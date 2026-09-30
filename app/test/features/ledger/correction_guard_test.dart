import 'package:cajui/src/features/ledger/application/correction_guard.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = LocalDate(2026, 9, 20);

Entry _entry(
  String id, {
  required int cents,
  String method = 'voucher',
  String what = 'Feira',
}) {
  final book = DefaultCatalog.emptyBook;
  return Entry.create(
    id: id,
    description: what,
    amount: Money.fromCents(cents),
    occurredOn: _today,
    category: book.categoryOf('groceries'),
    paymentLines: [book.methodOf(method).line(Money.fromCents(cents))],
    today: _today,
  ).valueOrNull!;
}

/// Crédito de R$ 100,00 e duas compras de R$ 80,00 no vale, como chegam de
/// dois celulares: o vale fica R$ 60,00 a descoberto.
LedgerBook _overdrawn() => [
  IncomeReceived(
    IncomeReceipt(
      id: 'credito',
      tender: Tender.mealVoucher,
      amount: const Money.fromCents(10000),
      receivedOn: _today,
    ),
  ),
  EntryRecorded(_entry('a', cents: 8000)),
  EntryRecorded(_entry('b', cents: 8000)),
].fold(DefaultCatalog.emptyBook, (book, event) => book.apply(event));

void main() {
  group('RN-124 · corrigir com o vale a descoberto', () {
    test('corrigir só a descrição passa: a correção não põe nada a mais no '
        'vale', () {
      final book = _overdrawn();

      final refusal = CorrectionGuard.refusalOf(
        book,
        book.entryOf('a')!,
        _entry('a', cents: 8000, what: 'Feira de sábado'),
      );

      expect(refusal, isNull);
    });

    test('tirar do vale passa — é justamente o conserto do descoberto', () {
      final book = _overdrawn();

      final menos = CorrectionGuard.refusalOf(
        book,
        book.entryOf('a')!,
        _entry('a', cents: 5000),
      );
      final noPix = CorrectionGuard.refusalOf(
        book,
        book.entryOf('a')!,
        _entry('a', cents: 8000, method: 'pix'),
      );

      expect(menos, isNull);
      expect(noPix, isNull);
    });

    test('RN-122 · pôr mais no vale continua sendo recusado sem saldo', () {
      final book = _overdrawn();

      final refusal = CorrectionGuard.refusalOf(
        book,
        book.entryOf('a')!,
        _entry('a', cents: 9000),
      );

      expect(refusal, isA<VoucherBalanceExceeded>());
    });
  });
}
