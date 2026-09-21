import 'package:cajui/src/features/budget/application/month_setup.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso do livro de lançamentos: abrir, lançar e corrigir o saldo
/// do vale.
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
    final result = Entry.create(
      // Lançamento que nasce de um comprovante usa a chave gerada na chegada
      // dele: confirmar duas vezes o mesmo comprovante grava um fato só.
      id: draft.captureId ?? ref.read(newIdProvider)(),
      origin: draft.origin,
      description: draft.description.trim(),
      amount: Money.fromCents(draft.amountCents),
      occurredOn: draft.occurredOn,
      category: draft.category!,
      paymentLines: draft.lines,
      today: ref.read(clockProvider).today(),
      installmentPlan: _planOf(draft, book),
    );
    final entry = result.valueOrNull;
    if (entry == null) return result;
    // Já gravado: repetir a confirmação não lança de novo (RN-781).
    if (book.entries.any((known) => known.id == entry.id)) return result;
    final paid = book.voucher.pay(entry.paidByTender.mealVoucher);
    if (paid.failureOrNull case final failure?) return Err(failure);
    await _commit(book, EntryRecorded(entry));
    return result;
  }

  /// O parcelamento de [draft], quando a compra foi feita em mais de uma vez
  /// num cartão cadastrado. As parcelas saem do domínio, a partir do ciclo
  /// do cartão: a primeira é cobrada na fatura do ciclo da compra (RN-311).
  InstallmentPlan? _planOf(EntryDraft draft, LedgerBook book) {
    final card = book.cardOf(draft.method?.id ?? '');
    if (card == null || draft.installmentCount < 2) return null;
    return InstallmentPlan.forPurchase(
      card: card,
      purchasedOn: draft.occurredOn,
      principal: Money.fromCents(draft.amountCents),
      count: draft.installmentCount,
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

  /// Corrige o saldo do vale para [actual], o que a operadora mostra
  /// (RN-123). Saldo que já bate não gera fato nenhum.
  Future<void> setVoucherBalance(Money actual, {required String reason}) async {
    final book = await future;
    final adjustment = book.voucher.adjustmentTo(actual);
    if (adjustment.isZero) return;
    await _commit(
      book,
      VoucherBalanceAdjusted(
        id: 'voucher-adjust-${ref.read(newIdProvider)()}',
        adjustment: adjustment,
        on: ref.read(clockProvider).today(),
        reason: reason,
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

  Future<void> _commit(LedgerBook book, LedgerEvent event) async {
    await ref.read(ledgerJournalProvider).append(event);
    state = AsyncData(book.apply(event));
  }
}

/// O livro de lançamentos em vigor.
final ledgerProvider = AsyncNotifierProvider<LedgerController, LedgerBook>(
  LedgerController.new,
);
