import 'package:cajui/src/features/ledger/application/device_facts.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

/// Como cada fato muda o livro.
///
/// O registro guarda o que aconteceu; o livro é o que isso dá, aplicado em
/// ordem (ADR-004). Um fato antigo **nunca impede o livro de abrir**: o que
/// não fizer mais sentido — estorno de lançamento que sumiu, parcela além do
/// total — é ignorado, em vez de virar erro na abertura do app.
abstract final class LedgerProjection {
  /// O livro [book] depois de [event].
  ///
  /// Os fatos que sobem ao servidor como estão ficam guardados no livro, e
  /// o mesmo fato duas vezes muda o livro **uma**: duas descidas próximas
  /// não contam a mesma parcela paga em dobro (ADR-019).
  static LedgerBook apply(LedgerBook book, LedgerEvent event) {
    if (!DeviceFacts.covers(event)) return _applied(book, event);
    if (book.factIds.contains(event.id)) return book;
    return _applied(book.copyWith(trail: book.trail.keeping(event)), event);
  }

  static LedgerBook _applied(LedgerBook book, LedgerEvent event) {
    return switch (event) {
      EntryRecorded(:final entry) => _recorded(book, entry),
      EntryCorrected(:final entry) => _corrected(book, entry),
      EntryCancelled(:final entryId) => _cancelled(book, entryId),
      EntryReversed(:final reversal) => _reversed(book, reversal),
      IncomeReceived(:final receipt) => _received(book, receipt),
      VoucherBalanceAdjusted(:final adjustment) => _adjusted(book, adjustment),
      PlanDefined(:final setup) => book.copyWith(setup: setup),
      StatementSettled(:final settlement) => book.copyWith(
        settlements: [...book.settlements, settlement],
      ),
      DebtInstallmentPaid() => _installmentPaid(book, event),
      // Cartão, dívida e fechamento: a versão mais recente toma o lugar da
      // anterior, que continua no registro.
      CardDefined() => _cardDefined(book, event),
      DebtDefined(:final debt) => book.copyWith(
        debts: [...book.debts.where((known) => known.id != debt.id), debt],
      ),
      MonthClosed() ||
      BudgetDefined() ||
      DebtOrdered() => _planned(book, event),
    };
  }

  /// O plano da planilha e a ordem das dívidas (ADR-023). O fechamento
  /// antigo continua sendo lido e guardado para subir, mas não muda nenhum
  /// número: o mês a mês agora é calculado.
  static LedgerBook _planned(LedgerBook book, LedgerEvent event) =>
      switch (event) {
        BudgetDefined(:final plan) => book.copyWith(
          budget: book.budget.defined(plan),
        ),
        DebtOrdered(:final ids, :final definedAt) => book.copyWith(
          budget: book.budget.ordered(ids, definedAt),
        ),
        _ => book,
      };

  /// A versão mais velha do cartão pelo carimbo não passa por cima da mais
  /// nova (ADR-024): reler o registro, onde a versão do outro celular pode
  /// ter sido gravada antes da daqui, chega ao mesmo cartão de antes.
  static LedgerBook _cardDefined(LedgerBook book, CardDefined event) {
    final card = event.card;
    final current = book.trail.cardStamps[card.id];
    if (EditStamp.isNewer(current, event.definedAt)) return book;
    return book.copyWith(
      cards: [...book.cards.where((known) => known.id != card.id), card],
      trail: book.trail.stampingCard(card.id, event.definedAt),
    );
  }

  /// O fato já foi aceito quando aconteceu — aqui ou em outro aparelho — e
  /// não se recusa depois. Se os pagamentos passam do saldo, a conta mostra
  /// zero e guarda a diferença a descoberto, em vez de esquecer o que já
  /// somou: parar em zero no meio fazia dois celulares, com os mesmos
  /// fatos em outra ordem, chegarem a saldos diferentes (RN-124).
  static VoucherAccount _paying(VoucherAccount account, Entry entry) =>
      account.settle(entry.paidByTender.mealVoucher);

  /// O mesmo fato duas vezes muda o livro **uma**: o registro já ignora o
  /// repetido, e a projeção faz o mesmo — é o que impede duas descidas
  /// próximas de contar um lançamento em dobro na tela (BL-062).
  static LedgerBook _recorded(LedgerBook book, Entry entry) =>
      book.entryOf(entry.id) != null
      ? book
      : book.copyWith(
          entries: [...book.entries, entry],
          voucher: _paying(book.voucher, entry),
        );

  /// A versão corrigida entra **no lugar** da anterior, na mesma posição. O
  /// vale devolve o que a versão antiga tinha pago e paga o da nova.
  static LedgerBook _corrected(LedgerBook book, Entry next) {
    final previous = book.entryOf(next.id);
    if (previous == null) return book;
    final refunded = book.voucher.reverse(previous.paidByTender.mealVoucher);
    return book.copyWith(
      entries: [
        for (final entry in book.entries)
          if (entry.id == next.id) next else entry,
      ],
      voucher: _paying(refunded, next),
    );
  }

  /// O lançamento cancelado sai de toda visão, e os estornos dele vão junto.
  /// O vale recebe de volta o que ainda não tinha voltado por estorno; e, se
  /// o lançamento pagava uma parcela de dívida, ela volta a estar em aberto.
  static LedgerBook _cancelled(LedgerBook book, String entryId) {
    final entry = book.entryOf(entryId);
    if (entry == null) return book;
    final alreadyBack = book
        .reversedOf(entryId)
        .where((reversal) => reversal.line.tender == Tender.mealVoucher)
        .fold(Money.zero, (sum, reversal) => sum + reversal.line.amount);
    final stillOut = entry.paidByTender.mealVoucher - alreadyBack;
    return book.copyWith(
      trail: book.trail.cancelling(entryId),
      entries: [...book.entries.where((known) => known.id != entryId)],
      reversals: [...book.reversals.where((r) => r.entryId != entryId)],
      voucher: book.voucher.reverse(stillOut),
      debts: _withPaid(book, book.debtPayments[entryId], -1),
      debtPayments: {...book.debtPayments}..remove(entryId),
    );
  }

  /// O estorno volta pela mesma forma de pagamento: o de compra no vale
  /// devolve saldo ao vale (RN-211).
  static LedgerBook _reversed(LedgerBook book, Reversal reversal) {
    if (book.reversals.any((known) => known.id == reversal.id)) return book;
    final onVoucher = reversal.line.tender == Tender.mealVoucher;
    return book.copyWith(
      reversals: [...book.reversals, reversal],
      voucher: onVoucher
          ? book.voucher.reverse(reversal.line.amount)
          : book.voucher,
    );
  }

  /// O crédito do vale entra no saldo (RN-120); renda em dinheiro só fica
  /// registrada — o app não conhece o saldo da conta de ninguém.
  static LedgerBook _adjusted(LedgerBook book, VoucherAdjustment adjustment) {
    if (book.voucherAdjustments.any((a) => a.id == adjustment.id)) return book;
    return book.copyWith(
      voucher: book.voucher.adjust(adjustment.amount),
      voucherAdjustments: [...book.voucherAdjustments, adjustment],
    );
  }

  static LedgerBook _received(LedgerBook book, IncomeReceipt receipt) {
    if (book.receipts.any((known) => known.id == receipt.id)) return book;
    final onVoucher = receipt.tender == Tender.mealVoucher;
    return book.copyWith(
      receipts: [...book.receipts, receipt],
      voucher: onVoucher ? book.voucher.credit(receipt.amount) : book.voucher,
    );
  }

  /// A dívida conta mais uma parcela paga, e o lançamento fica ligado a ela
  /// (RN-520). O mesmo lançamento não paga duas parcelas.
  static LedgerBook _installmentPaid(
    LedgerBook book,
    DebtInstallmentPaid event,
  ) {
    if (book.debtPayments.containsKey(event.entryId)) return book;
    // Parcela paga por um lançamento que não existe aqui não conta: ele foi
    // cancelado, e no celular que recebe tudo do servidor ele nunca
    // chegou a existir. Sem isto, pagar, cancelar e pagar de novo contava
    // duas parcelas no aparelho reinstalado.
    if (book.entryOf(event.entryId) == null) return book;
    return book.copyWith(
      debts: _withPaid(book, event.debtId, 1),
      debtPayments: {...book.debtPayments, event.entryId: event.debtId},
    );
  }

  /// As dívidas com uma parcela paga a mais ([delta] = 1) ou a menos (−1) na
  /// de identificador [debtId]. Parcela além do total, ou aquém de zero, não
  /// existe: a dívida fica como está.
  static List<Debt> _withPaid(LedgerBook book, String? debtId, int delta) => [
    for (final debt in book.debts)
      if (debt.id == debtId) _moved(debt, delta) else debt,
  ];

  static Debt _moved(Debt debt, int delta) {
    final paid = debt.paidInstallments + delta;
    if (paid < 0 || paid > debt.totalInstallments) return debt;
    return delta > 0
        ? debt.withInstallmentPaid()
        : debt.withInstallmentReverted();
  }
}
