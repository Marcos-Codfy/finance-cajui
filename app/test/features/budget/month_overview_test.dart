import 'dart:io';

import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

void main() {
  late ProviderContainer container;

  MonthOverview overview() => container.read(monthOverviewProvider)!;

  setUp(() async {
    container = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
    );
    addTearDown(container.dispose);
    await container.read(ledgerProvider.future);
  });

  group('o mês de relance, com o plano de exemplo', () {
    test('RN-111 · o vale cobre o mercado antes do dinheiro, e só o que é '
        'dinheiro entra no variável do plano', () {
      expect(overview().plan.variableCash.cents, 41000);
      expect(overview().voucher.balance.cents, 65000);
    });

    test('sobra planejada: renda menos fixos, dívidas e variáveis pelo '
        'máximo', () {
      expect(overview().indicators.plannedResult.cents, 122800);
    });

    test('renda comprometida em fixos e dívidas: 49%', () {
      expect(overview().indicators.commitmentPercent, 49);
    });

    test('RN-641 · limite da semana de 14 a 20: o variável que resta, na '
        'proporção dos dias da semana sobre os que faltam no mês, para '
        'baixo', () {
      final week = overview().week;

      expect((week.week.start.day, week.week.end.day), (14, 20));
      // 410,00 × 7 dias ÷ 17 dias (de 14 a 30) = 168,8235… → 168,82.
      expect(week.limit.cents, 16882);
      expect(week.remaining.cents, 16882);
    });

    test(
      'RN-642 e RN-643 · lançar ônibus de 8,50 no Pix baixa o resta da semana '
      'em 8,50, e o vale não se mexe',
      () async {
        final book = await container.read(ledgerProvider.future);
        await container
            .read(ledgerProvider.notifier)
            .record(
              EntryDraft(
                amountCents: 850,
                description: 'Ônibus',
                category: book.categoryOf('transport'),
                method: book.methodOf('pix'),
                occurredOn: testToday,
              ),
            );

        expect(overview().week.remaining.cents, 16882 - 850);
        expect(overview().voucher.balance.cents, 65000);
      },
    );

    test(
      'RN-604 · sem renda cadastrada, a proporção é indefinida — nunca 0%',
      () async {
        await container
            .read(ledgerProvider.notifier)
            .definePlan(samplePlan.withMoney(cashIncome: Money.zero));

        expect(overview().hasIncome, isFalse);
        expect(overview().indicators.commitmentPercent, isNull);
      },
    );
  });

  test('o plano gravado no registro cifrado volta igual ao reabrir', () async {
    final directory = Directory.systemTemp.createTempSync('cajui-plan-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final codec = LedgerEventCodec(
      categoryOf: DefaultCatalog.emptyBook.categoryOf,
    );
    final journal = EventStoreLedgerJournal(
      store: await openEventStoreAt(directory),
      codec: codec,
    );
    await journal.append(PlanDefined(id: 'plan-1', setup: samplePlan));

    final reopened = EventStoreLedgerJournal(
      store: await openEventStoreAt(directory),
      codec: codec,
    );
    final setup = ((await reopened.readAll()).single as PlanDefined).setup;

    expect(setup.cashIncome, samplePlan.cashIncome);
    expect(setup.debtInstallments, samplePlan.debtInstallments);
    expect(setup.fixedExpenses.map((f) => f.name), ['Aluguel', 'Internet']);
    expect(setup.variableBudgets.last.range.max.cents, 26000);
    expect(setup.variableBudgets.first.voucherEligible, isTrue);
  });
}
