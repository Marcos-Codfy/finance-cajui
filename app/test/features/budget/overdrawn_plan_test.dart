import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Entry _onVoucher(String id, int cents) => Entry.create(
  id: id,
  description: 'Feira',
  amount: Money.fromCents(cents),
  occurredOn: LocalDate(2026, 9, 12),
  category: DefaultCatalog.emptyBook.categoryOf('groceries'),
  paymentLines: [
    DefaultCatalog.emptyBook.methodOf('voucher').line(Money.fromCents(cents)),
  ],
  today: testToday,
).valueOrNull!;

LedgerBook _book(List<LedgerEvent> events) =>
    events.fold(DefaultCatalog.emptyBook, (book, event) => book.apply(event));

void main() {
  test('RN-124 · o vale gasto a descoberto não vira vale disponível no plano: '
      'com 650,00 de vale e 800,00 lançados, o plano conta 650,00', () {
    final overview = MonthOverview.of(
      _book([
        ...samplePlanEvents,
        EntryRecorded(_onVoucher('a', 40000)),
        EntryRecorded(_onVoucher('b', 40000)),
      ]),
      testToday,
    );

    expect(overview.voucher.overdrawn, const Money.fromCents(15000));
    expect(overview.plan.voucherAvailable, const Money.fromCents(65000));
  });

  test('sem descoberto, o vale do plano é o que resta mais o que saiu', () {
    final overview = MonthOverview.of(
      _book([...samplePlanEvents, EntryRecorded(_onVoucher('a', 40000))]),
      testToday,
    );

    expect(overview.plan.voucherAvailable, const Money.fromCents(65000));
  });
}
