import 'dart:io';

import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/cards/application/statement_view.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

final BudgetMonth _september = testToday.budgetMonth;
const BudgetMonth _october = BudgetMonth(2026, 10);

Money _dueIn(LedgerBook book, BudgetMonth month) =>
    DebtSchedule.dueIn(month, debts: book.debts, entries: book.entries);

void main() {
  late ProviderContainer container;

  LedgerController ledger() => container.read(ledgerProvider.notifier);
  Future<LedgerBook> book() => container.read(ledgerProvider.future);

  /// O cartão do exemplo da especificação: fecha dia 25, vence dia 5.
  Future<CreditCard> card() async => (await ledger().defineCard(
    name: 'Cartão da casa',
    closingDay: 25,
    dueDay: 5,
  )).valueOrNull!;

  Future<Entry> buy(
    CreditCard card,
    String what,
    int cents, {
    required int day,
    String category = 'groceries',
    int installments = 1,
  }) async {
    final current = await book();
    final result = await ledger().record(
      EntryDraft(
        amountCents: cents,
        description: what,
        category: current.categoryOf(category),
        method: current.methodOf(card.id),
        occurredOn: LocalDate(2026, 9, day),
        installments: installments,
      ),
    );
    return result.valueOrNull!;
  }

  setUp(() async {
    container = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
    );
    addTearDown(container.dispose);
    await book();
  });

  group('cartão é forma de pagamento (RN-301, RN-302)', () {
    test('cadastrado, o cartão entra em "por onde foi pago" — e em nenhuma '
        'lista de categoria', () async {
      final defined = await card();
      final current = await book();

      expect(current.methodOf(defined.id).kind, PaymentMethodKind.creditCard);
      expect(
        current.categories.map((c) => c.name),
        isNot(contains(defined.name)),
      );
    });

    test(
      'E-CARD-01 · dia fora de 1 a 31 é recusado, e nada é gravado',
      () async {
        final result = await ledger().defineCard(
          name: 'Cartão',
          closingDay: 32,
          dueDay: 5,
        );

        expect(result.failureOrNull, isA<InvalidCardDay>());
        expect((await book()).cards, isEmpty);
      },
    );
  });

  group('compra à vista no cartão', () {
    test('RN-310 · conta no mês da compra', () async {
      await buy(
        await card(),
        'Ônibus do mês',
        5000,
        day: 18,
        category: 'transport',
      );
      expect((await book()).spentIn(_september).cash.cents, 5000);
    });

    test(
      'RN-340 · pagar a fatura não é lançamento nem muda o gasto do mês',
      () async {
        final defined = await card();
        await buy(defined, 'Mercado', 18640, day: 12);
        final spentBefore = (await book()).spentIn(_september);

        await ledger().settleStatement(
          card: defined,
          dueMonth: _october,
          amount: const Money.fromCents(18640),
        );
        final after = await book();

        expect(after.entries, hasLength(1));
        expect(after.spentIn(_september), spentBefore);
        expect(after.spentIn(_october), TenderAmounts.zero);
      },
    );
  });

  group('compra parcelada (RN-311 a RN-313)', () {
    test(
      'fogão de 960,00 em 6×, comprado em 19/09 no cartão que fecha dia 25: '
      'seis parcelas de 160,00, a primeira na fatura que vence em outubro',
      () async {
        final stove = await buy(
          await card(),
          'Fogão',
          96000,
          day: 19,
          category: 'home',
          installments: 6,
        );
        final plan = stove.installmentPlan!;

        expect(
          plan.installments.map((i) => i.amount.cents),
          everyElement(16000),
        );
        expect(plan.installments.first.dueMonth, _october);
        expect(plan.installments.last.dueMonth, const BudgetMonth(2027, 3));
      },
    );

    test('RN-312 · não consome o variável do mês: entra como compromisso no '
        'mês em que a fatura vence', () async {
      final before = container.read(homeViewProvider)!.budget.dayToDay;

      await buy(
        await card(),
        'Fogão',
        96000,
        day: 19,
        category: 'home',
        installments: 6,
      );
      final after = container.read(homeViewProvider)!.budget.dayToDay;
      final current = await book();

      expect(after, before);
      expect(_dueIn(current, _september), Money.zero);
      expect(_dueIn(current, _october).cents, 16000);
    });

    test(
      'RN-313 · a fatura mostra a parcela e o total ainda comprometido',
      () async {
        final defined = await card();
        await buy(
          defined,
          'Fogão',
          96000,
          day: 19,
          category: 'home',
          installments: 6,
        );
        await buy(defined, 'Mercado', 18640, day: 12);

        final open = StatementView.current(
          await book(),
          defined,
          testToday,
        ).last;
        final plan = open.parceled.single.installmentPlan!;

        expect(open.cycle.dueOn, LocalDate(2026, 10, 5));
        expect(open.isClosedOn(testToday), isFalse);
        expect(open.statement.total.cents, 18640 + 16000);
        expect(plan.installmentDueIn(_october)!.number, 1);
        expect(plan.committedFrom(_october).cents, 96000);
      },
    );
  });

  test('cartão, compra parcelada e pagamento de fatura voltam iguais do '
      'registro cifrado', () async {
    final directory = Directory.systemTemp.createTempSync('cajui-card-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Future<ProviderContainer> open() async {
      final opened = ProviderContainer(
        overrides: testOverrides(
          journal: EventStoreLedgerJournal(
            store: await openEventStoreAt(directory),
            codec: LedgerEventCodec(
              categoryOf: DefaultCatalog.emptyBook.categoryOf,
            ),
          ),
        ),
      );
      addTearDown(opened.dispose);
      return opened;
    }

    container = await open();
    final defined = await card();
    await buy(
      defined,
      'Fogão',
      96000,
      day: 19,
      category: 'home',
      installments: 6,
    );
    await ledger().settleStatement(
      card: defined,
      dueMonth: _october,
      amount: const Money.fromCents(16000),
    );

    final reopened = await (await open()).read(ledgerProvider.future);

    expect(reopened.cards.single.name, 'Cartão da casa');
    expect(reopened.entries.single.installmentPlan!.count, 6);
    expect(_dueIn(reopened, _october).cents, 16000);
    expect(reopened.settlements.single.amount.cents, 16000);
  });
}
