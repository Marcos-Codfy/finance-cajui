import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

/// O cartão da casa, com o dia de fechamento e o limite dados.
CreditCard _card({int closingDay = 25, int limitCents = 500000}) =>
    CreditCard.create(
      id: 'card-casa',
      name: 'Cartão da casa',
      closingDay: closingDay,
      dueDay: 5,
      creditLimit: Money.fromCents(limitCents),
    ).valueOrNull!;

void main() {
  late FakeExchange server;
  late ProviderContainer a;
  late ProviderContainer b;

  setUp(() {
    server = FakeExchange();
    a = TwoPhones.on(server);
    // O relógio de B está um dia à frente: as edições dele são as novas.
    b = TwoPhones.on(server, today: testToday.addDays(1));
  });

  Future<void> define(
    ProviderContainer phone, {
    int closingDay = 25,
    int limitCents = 500000,
  }) async {
    final result = await phone
        .read(ledgerProvider.notifier)
        .defineCard(
          id: 'card-casa',
          name: 'Cartão da casa',
          closingDay: closingDay,
          dueDay: 5,
          creditLimit: Money.fromCents(limitCents),
        );
    expect(result.valueOrNull, isNotNull);
  }

  Future<LedgerBook> bookOf(ProviderContainer phone) =>
      phone.read(ledgerProvider.future);

  group('ADR-024 · BL-065 (a) · o cartão editado atravessa', () {
    test('trocar o dia de fechamento e o limite num celular chega ao '
        'outro, sem duplicar o cartão', () async {
      await define(a);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      await define(b, closingDay: 28, limitCents: 650000);
      await TwoPhones.sync(b);
      final backOnA = await TwoPhones.sync(a);

      expect(backOnA.cards, hasLength(1));
      expect(backOnA.cardOf('card-casa')!.closingDay, 28);
      expect(
        backOnA.cardOf('card-casa')!.creditLimit,
        const Money.fromCents(650000),
      );
    });

    test('duas edições ao mesmo tempo: vale a mais nova pelo carimbo, nos '
        'dois celulares', () async {
      await define(a);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      await define(b, closingDay: 28);
      await TwoPhones.sync(b);
      // A edita antes de descer a edição de B, com o relógio de ontem.
      await define(a, closingDay: 10);
      final onA = await TwoPhones.sync(a);
      final onB = await TwoPhones.sync(b);

      expect(onA.cardOf('card-casa')!.closingDay, 28);
      expect(onB.cardOf('card-casa')!.closingDay, 28);
    });

    test('BL-064 · quem edita depois de ver a edição do outro vence, mesmo '
        'com o relógio atrasado — e a edição aparece na hora', () async {
      await define(a);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);
      await define(b, closingDay: 28);
      await TwoPhones.sync(b);
      await TwoPhones.sync(a);

      await define(a, closingDay: 12);
      expect((await bookOf(a)).cardOf('card-casa')!.closingDay, 12);
      await TwoPhones.sync(a);
      final onB = await TwoPhones.sync(b);

      expect(onB.cardOf('card-casa')!.closingDay, 12);
    });

    test('a versão que desce leva o carimbo junto, e uma segunda versão '
        'também desce: a chave dela não repete a da primeira', () async {
      await define(b);
      await TwoPhones.sync(b);
      await TwoPhones.sync(a);
      await define(b, closingDay: 27);
      await TwoPhones.sync(b);

      final onA = await TwoPhones.sync(a);

      expect(onA.cardOf('card-casa')!.closingDay, 27);
      expect(onA.trail.cardStamps['card-casa'], isNotNull);
    });
  });

  group('ADR-024 · o carimbo do cartão no registro do aparelho', () {
    final monday = DateTime.utc(2026, 9, 14, 9);
    final friday = DateTime.utc(2026, 9, 18, 18);
    const codec = LedgerEventCodec(categoryOf: _category);

    test('vai e volta pelo registro; o cartão de antes do carimbo volta '
        'sem ele', () {
      final stamped = codec.encode(
        CardDefined(id: 'c1', card: _card(), definedAt: friday),
      );
      final legacy = CardCodec.encodeCard(_card());

      final back = codec.decode('c1', stamped.type, stamped.payload);
      final old = codec.decode('c0', LedgerEventCodec.cardDefined, legacy);

      expect((back! as CardDefined).definedAt, friday);
      expect((old! as CardDefined).definedAt, isNull);
    });

    test('ADR-004 · reabrir o app chega ao mesmo cartão, mesmo com a '
        'versão mais velha gravada por último', () async {
      final phone = ProviderContainer(
        overrides: testOverrides(
          journal: MemoryLedgerJournal([
            CardDefined(id: 'c0', card: _card(closingDay: 20)),
            CardDefined(
              id: 'c1',
              card: _card(closingDay: 28),
              definedAt: friday,
            ),
            CardDefined(
              id: 'c2',
              card: _card(closingDay: 10),
              definedAt: monday,
            ),
          ]),
        ),
      );
      addTearDown(phone.dispose);

      final book = await bookOf(phone);

      expect(book.cards.single.closingDay, 28);
      expect(book.trail.cardStamps['card-casa'], friday);
    });
  });
}

Category _category(String id) => DefaultCatalog.emptyBook.categoryOf(id);
