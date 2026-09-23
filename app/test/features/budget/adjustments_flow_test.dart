import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// Um plano que **não fecha**: a renda cobre os fixos e as dívidas, mas os
/// variáveis pelo pior caso passam do que sobra. É o caso da RN-662.
final MonthSetup _apertado = samplePlan.withMoney(
  cashIncome: const Money.fromCents(180000),
);

Future<ProviderContainer> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal();
  final scope = ProviderContainer(overrides: testOverrides(journal: journal));
  addTearDown(scope.dispose);
  await scope.read(ledgerProvider.notifier).definePlan(_apertado);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: scope, child: const CajuiApp()),
  );
  await tester.pump();
  return scope;
}

void main() {
  testWidgets('RN-662 · o painel deixa de só informar e oferece o caminho', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Ver os ajustes'), findsOneWidget);
  });

  testWidgets('RN-663 · aceitar um ajuste muda o plano, e só com o toque', (
    tester,
  ) async {
    final scope = await _open(tester);
    final antes = scope.read(ledgerProvider).value!.setup.variableBudgets;

    await tester.tap(find.text('Ver os ajustes'));
    await tester.pumpAndSettle();

    // As opções vêm da maior folga para a menor, e nenhuma foi aplicada.
    expect(find.text('Ajustes possíveis'), findsOneWidget);
    expect(
      scope.read(ledgerProvider).value!.setup.variableBudgets,
      antes,
      reason: 'RN-663: nada se aplica sozinho',
    );

    await tester.tap(find.textContaining('Usar ').first);
    await tester.pumpAndSettle();

    final depois = scope.read(ledgerProvider).value!.setup.variableBudgets;
    expect(
      depois.map((b) => b.range.max.cents).reduce((a, b) => a + b),
      lessThan(antes.map((b) => b.range.max.cents).reduce((a, b) => a + b)),
      reason: 'a faixa escolhida baixou',
    );
  });
}
