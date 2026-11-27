import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

BudgetLine _line(String id, int cents, LineGroup group, String category) =>
    BudgetLine.create(
      id: id,
      name: id,
      amount: Money.fromCents(cents),
      group: group,
      categoryId: category,
    ).valueOrNull!;

/// Uma casa inventada: salário de R$ 3.000,00, aluguel de R$ 1.000,00 e
/// mercado de R$ 800,00 — sobra de R$ 1.200,00.
final BudgetDefined _plan = BudgetDefined(
  BudgetPlan(
    salaries: const [
      IncomeSource(
        id: 'ana',
        name: 'Ana',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(300000),
        expectedDay: 5,
      ),
    ],
    lines: [
      _line('Aluguel', 100000, LineGroup.fixedBill, 'rent'),
      _line('Mercado', 80000, LineGroup.dayToDay, 'groceries'),
    ],
    definedAt: DateTime.utc(2026, 9),
  ),
);

Future<void> _openPanel(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal([_plan])),
      child: const CajuiApp(),
    ),
  );
  await settleAfterTap(tester);
  await tester.tap(find.bySemanticsLabel('Painel'));
  await settleAfterTap(tester);
}

void main() {
  testWidgets('cada página do carrossel tem nome, e o nome leva até ela', (
    tester,
  ) async {
    await _openPanel(tester);

    expect(find.text('Sobra'), findsOneWidget);
    expect(find.text('Renda'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    // Sem vale no plano, não há página do vale.
    expect(find.text('Vale'), findsNothing);

    await tester.tap(find.text('Renda'));
    await settleAfterTap(tester);

    expect(find.text('Renda do mês'), findsOneWidget);
    expect(find.textContaining('sai do bolso'), findsNothing);
  });

  testWidgets('tocar no número abre a conta por trás dele, no Meu mês', (
    tester,
  ) async {
    await _openPanel(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('^Sobra de .*Ver a conta')));
    await settleAfterTap(tester);

    expect(find.text('Meu mês'), findsWidgets);
    expect(find.text('Renda do mês'), findsWidgets);
  });
}
