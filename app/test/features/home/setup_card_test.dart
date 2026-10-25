import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/home/application/setup_steps.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _open(WidgetTester tester, List<SetupStep> steps) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
        setupStepsProvider.overrideWith((ref) async => steps),
      ],
      child: const CajuiApp(),
    ),
  );
  await settleAfterTap(tester);
  await tester.tap(find.bySemanticsLabel('Painel'));
  await settleAfterTap(tester);
}

void main() {
  group('Primeiros passos no Início', () {
    testWidgets('mostra o que falta, e cada linha leva ao lugar', (
      tester,
    ) async {
      await _open(tester, const [SetupStep.names, SetupStep.cardLimits]);

      expect(find.text('Primeiros passos'), findsOneWidget);
      expect(find.text('Informe o limite dos cartões'), findsOneWidget);
      final names = find.bySemanticsLabel('Cadastre os nomes da casa');
      await tester.ensureVisible(names);
      await tester.tap(names);
      await settleAfterTap(tester);

      expect(find.text('Nomes da casa'), findsWidgets);
    });

    testWidgets('com tudo pronto, o cartão não aparece', (tester) async {
      await _open(tester, const []);

      expect(find.text('Primeiros passos'), findsNothing);
    });
  });

  test('o que falta sai do livro, do acesso e do widget', () async {
    final container = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
    );
    addTearDown(container.dispose);

    final steps = await container.read(setupStepsProvider.future);

    // No teste não há nomes da casa nem acesso às notificações; o widget
    // não se põe por pedido, e o plano de exemplo não tem cartão.
    expect(steps, [SetupStep.names, SetupStep.notifications]);
  });
}
