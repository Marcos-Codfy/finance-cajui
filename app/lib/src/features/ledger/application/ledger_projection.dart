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
  static LedgerBook apply(LedgerBook book, LedgerEvent event) {
    return switch (event) {
      EntryRecorded(:final entry) => _recorded(book, entry),
      EntryCorrected(:final entry) => _corrected(book, entry),
      EntryCancelled(:final entryId) => _cancelled(book, entryId),
      EntryReversed(:final reversal) => _reversed(book, reversal),
      IncomeReceived(:final receipt) => _received(book, receipt),
      VoucherBalanceAdjusted(:final adjustment) => book.copyWith(
        voucher: book.voucher.adjust(adjustment.amount),
        voucherAdjustments: [...book.voucherAdjustments, adjustment],
      ),
      PlanDefined(:final setup) => book.copyWith(setup: setup),
      StatementSettled(:final settlement) => book.copyWith(
        settlements: [...book.settlements, settlement],
      ),
      DebtInstallmentPaid() => _installmentPaid(book, event),
      // Cartão, dívida e fechamento: a versão mais recente toma o lugar da
      // anterior, que continua no registro.
      CardDefined(:final card) => book.copyWith(
        cards: [...book.cards.where((known) => known.id != card.id), card],
      ),
      DebtDefined(:final debt) => book.copyWith(
        debts: [...book.debts.where((known) => known.id != debt.id), debt],
      ),
      MonthClosed(:final close) => _closed(book, close),
    };
  }

  static LedgerBook _closed(LedgerBook book, MonthClose close) => book.copyWith(
    closes: [
      ...book.closes.where((known) => known.month != close.month),
      close,
    ],
  );

  /// O fato já foi aceito quando aconteceu. Se o registro antigo disser que
  /// o vale pagou mais do que tinha, o saldo para em zero: é melhor abrir
  /// com saldo zerado do que não abrir.
  static VoucherAccount _paying(VoucherAccount account, Entry entry) =>
      account.pay(entry.paidByTender.mealVoucher).valueOrNull ??
      VoucherAccount();

  static LedgerBook _recorded(LedgerBook book, Entry entry) => book.copyWith(
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
      cancelledIds: {...book.cancelledIds, entryId},
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
  static LedgerBook _received(LedgerBook book, IncomeReceipt receipt) {
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
