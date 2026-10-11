import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:cajui/src/features/settings/application/household_names_service.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/household_book.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

HouseholdNamed _named(List<String> names, DateTime at) =>
    HouseholdNamed(HouseholdNames(names: names, definedAt: at));

void main() {
  group('RN-1070 · os nomes da casa atravessam os dois celulares', () {
    late FakeExchange server;
    late ProviderContainer a;
    late ProviderContainer b;

    setUp(() {
      server = FakeExchange();
      a = TwoPhones.on(server);
      b = TwoPhones.on(server, today: testToday.addDays(1));
    });

    test('o nome incluído num celular chega ao outro, que o motor das '
        'notificações lê', () async {
      await a.read(householdNamesServiceProvider).add(testHouseholdName);
      await TwoPhones.sync(a);

      final onB = await TwoPhones.sync(b);

      expect(onB.householdNames.names, [testHouseholdName]);
    });

    test(
      'ADR-024 · vale a lista decidida por último, chegue quando chegar',
      () async {
        await a.read(householdNamesServiceProvider).add(testHouseholdName);
        await TwoPhones.sync(a);
        await TwoPhones.sync(b);
        await b.read(householdNamesServiceProvider).remove(testHouseholdName);
        await TwoPhones.sync(b);

        final onA = await TwoPhones.sync(a);

        expect(onA.householdNames.names, isEmpty);
      },
    );
  });

  test('ADR-024 · a lista mais velha, relida depois da nova, não passa por '
      'cima dela', () {
    final newer = _named(const [
      'Beatriz Souza Lima',
    ], DateTime.utc(2026, 9, 2));
    final older = _named(const [testHouseholdName], DateTime.utc(2026, 8, 30));
    final book = LedgerBook(
      categories: DefaultCatalog.categories,
      paymentMethods: DefaultCatalog.paymentMethods,
    );

    final after = book.apply(newer).apply(older);

    expect(after.householdNames.names, ['Beatriz Souza Lima']);
  });

  test('o fato vai e volta pelo registro do aparelho', () {
    final codec = LedgerEventCodec(
      categoryOf: (id) =>
          DefaultCatalog.categories.firstWhere((c) => c.id == id),
    );
    final event = _named(const [testHouseholdName], DateTime.utc(2026, 9, 5));

    final (:type, :payload) = codec.encode(event);
    final back = codec.decode(event.id, type, payload)! as HouseholdNamed;

    expect(type, 'household.named');
    expect(back.id, event.id);
    expect(back.names.names, [testHouseholdName]);
  });
}
