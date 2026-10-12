import 'package:cajui/src/features/ledger/application/correction_guard.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/draft_defaults.dart';
import 'package:cajui/src/features/ledger/application/entry_changes.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_reload.dart';
import 'package:cajui/src/features/ledger/application/quiet_sync.dart';
import 'package:cajui/src/features/ledger/application/serial_queue.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso do livro de lançamentos: abrir, lançar, corrigir, cancelar,
/// estornar e acertar o saldo do vale.
///
/// O caminho de toda escrita é o mesmo do servidor: aplicar as regras do
/// domínio, **gravar o fato** e só então mudar o estado que a tela vê. Se a
/// gravação falhar, a tela nunca chega a mostrar o que não foi salvo.
class LedgerController extends AsyncNotifier<LedgerBook> with LedgerReload {
  @override
  Future<LedgerBook> build() async {
    final events = await ref.watch(ledgerJournalProvider).readAll();
    return events.fold<LedgerBook>(
      DefaultCatalog.emptyBook,
      (book, event) => book.apply(event),
    );
  }

  /// Tenta lançar [raw]. A recusa de uma regra volta como falha tipada;
  /// nada é gravado nesse caso.
  Future<Result<Entry>> record(EntryDraft raw) async {
    final book = await future;
    // O que a pessoa não escolheu, o app escolhe (ver `DraftDefaults`).
    final draft = DraftDefaults.complete(raw, book);
    // Lançamento que nasce de um comprovante usa a chave gerada na chegada
    // dele: confirmar duas vezes o mesmo comprovante grava um fato só.
    final id = draft.captureId ?? ref.read(newIdProvider)();
    final result = _entryFrom(draft, book, id: id, origin: draft.origin);
    final entry = result.valueOrNull;
    if (entry == null) return result;
    // Já gravado: repetir a confirmação não lança de novo (RN-781).
    if (book.entryOf(entry.id) != null) return result;
    // O vale não é recusado por saldo: na planilha do dono (ADR-023) ele é o
    // vale do mês, e o que passar dele só deixa de ser coberto (RN-1019).
    // Recusar pelo saldo da operadora, que a tela nem mostra mais, travava
    // a compra no mercado com "Vale do mês: R$ 500" à vista.
    await _commit(book, EntryRecorded(entry));
    return result;
  }

  Result<Entry> _entryFrom(
    EntryDraft draft,
    LedgerBook book, {
    required String id,
    required EntryOrigin origin,
    DateTime? revisedAt,
  }) {
    return Entry.create(
      id: id,
      origin: origin,
      revisedAt: revisedAt,
      description: draft.description.trim(),
      amount: Money.fromCents(draft.amountCents),
      // `isComplete` já garantiu os dois: o rascunho não chega aqui sem
      // data nem sem categoria.
      occurredOn: draft.occurredOn!,
      category: draft.category!,
      paymentLines: draft.lines,
      today: ref.read(clockProvider).today(),
      installmentPlan: draft.installmentPlanFor(
        book.cardOf(draft.method?.id ?? ''),
      ),
    );
  }

  /// Corrige o lançamento que [raw] aponta em `correctionOf` (RN-208). As
  /// regras são as mesmas de lançar; o original fica no registro, e a versão
  /// nova passa a valer em toda visão. Sem mudança, nenhum fato é gravado.
  /// Lançamento que já não existe — cancelado em outro aparelho enquanto a
  /// correção estava aberta — é recusado, e nada é gravado.
  Future<Result<Entry>> correct(EntryDraft raw) async {
    final book = await future;
    final draft = DraftDefaults.complete(raw, book);
    final original = book.entryOf(draft.correctionOf!);
    if (original == null) return Err(EntryNoLongerExists(draft.correctionOf!));
    // O carimbo decide entre dois celulares: vale a correção mais nova.
    final result = _entryFrom(
      draft,
      book,
      id: original.id,
      origin: original.origin,
      revisedAt: ref.read(clockProvider).now(),
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
      CardDefined(
        id: 'card-fact-${ref.read(newIdProvider)()}',
        card: card,
        definedAt: book.trail.nextCardStamp(
          card.id,
          ref.read(clockProvider).now(),
        ),
      ),
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

  /// Passa a valer o plano [setup]. Plano igual ao que já vale não gera fato.
  Future<void> definePlan(MonthSetup setup) async {
    final book = await future;
    if (identical(setup, book.setup)) return;
    await _commit(
      book,
      PlanDefined(
        id: 'plan-${ref.read(newIdProvider)()}',
        // O carimbo é o que decide entre dois celulares: o plano editado
        // por último vence, e não o que chegou por último ao servidor.
        setup: setup.stamped(ref.read(clockProvider).now()),
      ),
    );
  }

  /// Grava um fato que **veio do servidor** — o que outro aparelho fez
  /// (BL-062). Igual a [append], menos em duas coisas: não dispara nova
  /// subida, porque o que desceu não precisa voltar; e confere, já na
  /// fila e contra o livro em vigor, se o fato ainda faz diferença — duas
  /// sincronizações próximas trazem o mesmo fato, e ele entra uma vez.
  /// Devolve se entrou.
  Future<bool> absorb(LedgerEvent event) => _queue.run(() async {
    final book = state.value ?? await future;
    if (!LedgerPull.accepts(book, event)) return false;
    await _write(book, event, quietly: true);
    return true;
  });

  /// Grava [event] e só então muda o que a tela vê. É a porta por onde os
  /// casos de uso de outras features — dívidas, fechamento — escrevem no
  /// mesmo registro, sem um segundo dono do livro.
  Future<void> append(LedgerEvent event) async {
    await _commit(await future, event);
  }

  /// Como [append], mas o fato nasce **na fila**, do livro em vigor: [make]
  /// o monta, ou devolve `null` quando não há o que gravar. É para o fato
  /// que depende do que já está no livro, que, montado fora, perderia o que
  /// a gravação anterior acabou de pôr. Devolve o que gravou.
  Future<LedgerEvent?> appendFrom(LedgerEvent? Function(LedgerBook) make) =>
      _queue.run(() async {
        final book = state.value ?? await future;
        final event = make(book);
        if (event != null) await _write(book, event, quietly: false);
        return event;
      });

  /// Um fato de cada vez (ver [SerialQueue]): dois entrelaçados apagariam
  /// um ao outro da tela.
  Future<void> _commit(
    LedgerBook book,
    LedgerEvent event, {
    bool quietly = false,
  }) => _queue.run(() => _write(book, event, quietly: quietly));

  final _queue = SerialQueue();

  Future<void> _write(
    LedgerBook book,
    LedgerEvent event, {
    required bool quietly,
  }) async {
    await ref.read(ledgerJournalProvider).append(event);
    // Aplica sobre o livro **em vigor**, e não sobre o que o caso de uso leu
    // antes de gravar: entre uma coisa e outra pode ter descido um fato de
    // outro aparelho, e aplicar sobre o livro velho o apagaria da tela até
    // o app reabrir.
    // O mês a mês é calculado (ADR-023): nenhum fechamento é gravado aqui.
    final next = (state.value ?? book).apply(event);
    state = AsyncData(next);
    if (!quietly) quietSync.schedule(next);
  }

  /// A cópia para o servidor, que acontece sozinha e não aparece na tela —
  /// e que traz de volta o que outro aparelho fez.
  late final QuietSync quietSync = QuietSync.over(ref, absorb: absorb);
}

/// O livro de lançamentos em vigor.
final ledgerProvider = AsyncNotifierProvider<LedgerController, LedgerBook>(
  LedgerController.new,
);
