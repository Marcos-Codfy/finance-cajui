import 'package:cajui/src/features/budget/application/close_revision.dart';
import 'package:cajui/src/features/ledger/application/correction_guard.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_changes.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/quiet_sync.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso do livro de lançamentos: abrir, lançar, corrigir, cancelar,
/// estornar e acertar o saldo do vale.
///
/// O caminho de toda escrita é o mesmo do servidor: aplicar as regras do
/// domínio, **gravar o fato** e só então mudar o estado que a tela vê. Se a
/// gravação falhar, a tela nunca chega a mostrar o que não foi salvo.
class LedgerController extends AsyncNotifier<LedgerBook> {
  @override
  Future<LedgerBook> build() async {
    final events = await ref.watch(ledgerJournalProvider).readAll();
    return events.fold<LedgerBook>(
      DefaultCatalog.emptyBook,
      (book, event) => book.apply(event),
    );
  }

  /// Tenta lançar [draft]. A recusa de uma regra volta como falha tipada;
  /// nada é gravado nesse caso.
  Future<Result<Entry>> record(EntryDraft draft) async {
    final book = await future;
    // Lançamento que nasce de um comprovante usa a chave gerada na chegada
    // dele: confirmar duas vezes o mesmo comprovante grava um fato só.
    final id = draft.captureId ?? ref.read(newIdProvider)();
    final result = _entryFrom(draft, book, id: id, origin: draft.origin);
    final entry = result.valueOrNull;
    if (entry == null) return result;
    // Já gravado: repetir a confirmação não lança de novo (RN-781).
    if (book.entryOf(entry.id) != null) return result;
    final paid = book.voucher.pay(entry.paidByTender.mealVoucher);
    if (paid.failureOrNull case final failure?) return Err(failure);
    await _commit(book, EntryRecorded(entry));
    return result;
  }

  Result<Entry> _entryFrom(
    EntryDraft draft,
    LedgerBook book, {
    required String id,
    required EntryOrigin origin,
  }) {
    return Entry.create(
      id: id,
      origin: origin,
      description: draft.description.trim(),
      amount: Money.fromCents(draft.amountCents),
      // `isComplete` já garantiu os dois: o rascunho não chega aqui sem
      // data nem sem categoria.
      occurredOn: draft.occurredOn!,
      category: draft.category!,
      paymentLines: draft.lines,
      today: ref.read(clockProvider).today(),
      installmentPlan: _planOf(draft, book),
    );
  }

  /// Corrige o lançamento que [draft] aponta em `correctionOf` (RN-208). As
  /// regras são as mesmas de lançar; o original fica no registro, e a versão
  /// nova passa a valer em toda visão. Sem mudança, nenhum fato é gravado.
  Future<Result<Entry>> correct(EntryDraft draft) async {
    final book = await future;
    final original = book.entryOf(draft.correctionOf!)!;
    final result = _entryFrom(
      draft,
      book,
      id: original.id,
      origin: original.origin,
    );
    final entry = result.valueOrNull;
    if (entry == null) return result;
    final changes = EntryChanges.between(original, entry);
    if (changes.isEmpty) return result;
    final refusal = CorrectionGuard.refusalOf(book, original, entry);
    if (refusal != null) return Err(refusal);
    await _commit(
      book,
      EntryCorrected(
        id: 'correction-${ref.read(newIdProvider)()}',
        entry: entry,
        on: ref.read(clockProvider).today(),
        reason: changes.join(', '),
      ),
    );
    return result;
  }

  /// Cancela o lançamento [entryId] (RN-208): ele sai de toda visão e de toda
  /// conta, e o que o vale tinha pago volta ao saldo. O fato original fica no
  /// registro.
  Future<void> cancel(String entryId, {required String reason}) async {
    final book = await future;
    if (book.entryOf(entryId) == null) return;
    await _commit(
      book,
      EntryCancelled(
        id: 'cancellation-${ref.read(newIdProvider)()}',
        entryId: entryId,
        on: ref.read(clockProvider).today(),
        reason: reason,
      ),
    );
  }

  /// Registra que [amount] da compra [entry] voltou pela forma
  /// [paymentMethodId], no dia [occurredOn] (RN-209 e RN-211). O domínio
  /// recusa o que passar do que ainda resta naquela linha (RN-210).
  Future<Result<Reversal>> reverse({
    required Entry entry,
    required String paymentMethodId,
    required Money amount,
    required LocalDate occurredOn,
  }) async {
    final book = await future;
    final result = Reversal.create(
      id: ref.read(newIdProvider)(),
      entry: entry,
      paymentMethodId: paymentMethodId,
      amount: amount,
      occurredOn: occurredOn,
      previous: book.reversedOf(entry.id),
    );
    final reversal = result.valueOrNull;
    if (reversal != null) await _commit(book, EntryReversed(reversal));
    return result;
  }

  /// O parcelamento de [draft], quando a compra foi feita em mais de uma vez
  /// num cartão cadastrado. As parcelas saem do domínio, a partir do ciclo
  /// do cartão: a primeira é cobrada na fatura do ciclo da compra (RN-311).
  InstallmentPlan? _planOf(EntryDraft draft, LedgerBook book) {
    final card = book.cardOf(draft.method?.id ?? '');
    if (card == null || draft.installmentCount < 2) return null;
    final each = draft.installmentAmountCents;
    return InstallmentPlan.forPurchase(
      card: card,
      purchasedOn: draft.occurredOn!,
      principal: Money.fromCents(draft.amountCents),
      count: draft.installmentCount,
      // Parcela informada só quando ela **não** é o total dividido: aí a
      // diferença é juros, e o domínio a guarda como tal (RN-314).
      installmentAmount: each == null ? null : Money.fromCents(each),
    );
  }

  /// Cadastra ou altera um cartão de crédito. Dia inválido volta como falha
  /// do domínio (`E-CARD-01`), e nada é gravado.
  Future<Result<CreditCard>> defineCard({
    required String name,
    required int closingDay,
    required int dueDay,
    String? id,
    Money? creditLimit,
  }) async {
    final book = await future;
    final result = CreditCard.create(
      id: id ?? 'card-${ref.read(newIdProvider)()}',
      name: name.trim(),
      closingDay: closingDay,
      dueDay: dueDay,
      creditLimit: creditLimit,
    );
    final card = result.valueOrNull;
    if (card == null) return result;
    await _commit(
      book,
      CardDefined(id: 'card-fact-${ref.read(newIdProvider)()}', card: card),
    );
    return result;
  }

  /// Registra o pagamento da fatura de [card] que vence em [dueMonth]. É uma
  /// liquidação, não um lançamento (RN-340): as compras já contaram quando
  /// foram feitas, e pagar a fatura não é gastar de novo.
  Future<void> settleStatement({
    required CreditCard card,
    required BudgetMonth dueMonth,
    required Money amount,
  }) async {
    final book = await future;
    await _commit(
      book,
      StatementSettled(
        Settlement(
          id: ref.read(newIdProvider)(),
          cardId: card.id,
          dueMonth: dueMonth,
          amount: amount,
          paidOn: ref.read(clockProvider).today(),
        ),
      ),
    );
  }

  /// Registra uma renda recebida. Em dinheiro, [fromPlan] diz se é a renda do
  /// plano — que passa a valer no lugar da esperada no mês (RN-131) — ou uma
  /// entrada avulsa, contada só no mês em que entrou (RN-133). No vale, é o
  /// crédito que entra no saldo (RN-120). Valor zero não gera fato.
  Future<void> receiveIncome({
    required Tender tender,
    required Money amount,
    required LocalDate receivedOn,
    bool fromPlan = true,
  }) async {
    if (!amount.isPositive) return;
    final book = await future;
    final ofPlan = fromPlan && tender == Tender.cash;
    await _commit(
      book,
      IncomeReceived(
        IncomeReceipt(
          id: ref.read(newIdProvider)(),
          sourceId: ofPlan ? LedgerBook.cashIncomeSourceId : null,
          tender: tender,
          amount: amount,
          receivedOn: receivedOn,
        ),
      ),
    );
  }

  /// Corrige o saldo do vale para [actual], o que a operadora mostra
  /// (RN-123). Saldo que já bate não gera fato nenhum.
  Future<void> setVoucherBalance(Money actual, {required String reason}) async {
    final book = await future;
    final adjustment = book.voucher.adjustmentTo(actual);
    if (adjustment.isZero) return;
    await _commit(
      book,
      VoucherBalanceAdjusted(
        VoucherAdjustment(
          id: ref.read(newIdProvider)(),
          amount: adjustment,
          on: ref.read(clockProvider).today(),
          reason: reason,
        ),
      ),
    );
  }

  /// Passa a valer o plano [setup]. Plano igual ao que já vale não gera fato.
  Future<void> definePlan(MonthSetup setup) async {
    final book = await future;
    if (identical(setup, book.setup)) return;
    await _commit(
      book,
      PlanDefined(id: 'plan-${ref.read(newIdProvider)()}', setup: setup),
    );
  }

  /// Grava [event] e só então muda o que a tela vê. É a porta por onde os
  /// casos de uso de outras features — dívidas, fechamento — escrevem no
  /// mesmo registro, sem um segundo dono do livro.
  Future<void> append(LedgerEvent event) async {
    await _commit(await future, event);
  }

  Future<void> _commit(LedgerBook book, LedgerEvent event) async {
    await ref.read(ledgerJournalProvider).append(event);
    var next = book.apply(event);
    state = AsyncData(next);
    // Fato com data em mês já fechado é lançamento tardio: o fechamento não
    // é reescrito, ganha uma revisão (RN-441).
    for (final revision in CloseRevision.after(
      before: book,
      after: next,
      event: event,
      today: ref.read(clockProvider).today(),
    )) {
      await ref.read(ledgerJournalProvider).append(revision);
      next = next.apply(revision);
      state = AsyncData(next);
    }
    quietSync.schedule(next);
  }

  /// A cópia para o servidor, que acontece sozinha e não aparece na tela.
  late final QuietSync quietSync = QuietSync(ref.read(ledgerUplinkProvider));
}

/// O livro de lançamentos em vigor.
final ledgerProvider = AsyncNotifierProvider<LedgerController, LedgerBook>(
  LedgerController.new,
);
