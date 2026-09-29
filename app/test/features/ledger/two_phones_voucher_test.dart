import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

void main() {
  late FakeExchange server;
  late ProviderContainer a;
  late ProviderContainer b;

  setUp(() {
    server = FakeExchange();
    a = TwoPhones.on(server);
    b = TwoPhones.on(server, today: testToday.addDays(1));
  });

  Future<void> credit(ProviderContainer phone, int cents) => phone
      .read(incomeServiceProvider)
      .receiveIncome(
        tender: Tender.mealVoucher,
        amount: Money.fromCents(cents),
        receivedOn: testToday,
      );

  Future<void> spend(ProviderContainer phone, String what) async {
    final book = await phone.read(ledgerProvider.future);
    await phone
        .read(ledgerProvider.notifier)
        .record(
          TwoPhones.draft(book, cents: 8000, what: what, method: 'voucher'),
        );
  }

  group('RN-124 · o vale entre dois celulares', () {
    test('os dois gastam o mesmo saldo sem rede: o saldo para em zero nos '
        'dois, com a mesma diferença a descoberto', () async {
      await credit(a, 10000);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      await spend(a, 'Feira');
      await spend(b, 'Padaria');
      await TwoPhones.sync(a);
      final onB = await TwoPhones.sync(b);
      final onA = await TwoPhones.sync(a);

      expect(onA.entries, hasLength(2));
      expect(onA.voucher.balance, Money.zero);
      expect(onA.voucher.overdrawn, const Money.fromCents(6000));
      expect(onB.voucher, onA.voucher);
    });

    test('o crédito seguinte cobre primeiro o descoberto, nos dois', () async {
      await credit(a, 10000);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);
      await spend(a, 'Feira');
      await spend(b, 'Padaria');
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      await credit(b, 5000);
      final onB = await TwoPhones.sync(b);
      final onA = await TwoPhones.sync(a);

      expect(onA.voucher.balance, Money.zero);
      expect(onA.voucher.overdrawn, const Money.fromCents(1000));
      expect(onB.voucher, onA.voucher);
    });

    test('a descoberto, o celular não aceita gasto novo no vale '
        '(RN-122)', () async {
      await credit(a, 10000);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);
      await spend(a, 'Feira');
      await spend(b, 'Padaria');
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      final book = await b.read(ledgerProvider.future);
      final refused = await b
          .read(ledgerProvider.notifier)
          .record(TwoPhones.draft(book, cents: 100, method: 'voucher'));

      expect(refused.failureOrNull, isA<VoucherBalanceExceeded>());
    });
  });
}
