import 'package:cajui/src/app/cajui_app.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

void main() {
  testWidgets('o anel do Meu mês: tocar o grupo mostra as categorias dele, e '
      'a categoria abre os lançamentos filtrados', (tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(
          journal: MemoryLedgerJournal(samplePlanEvents),
        ),
        child: const CajuiApp(),
      ),
    );
    await settleAfterTap(tester);
    await openFromHome(tester, 'Meu mês');

    expect(find.text('Para onde foi'), findsOneWidget);
    expect(find.byType(CajuiRingChart), findsOneWidget);
    final group = find.descendant(
      of: find.byType(CajuiRingChart),
      matching: find.textContaining('Dia a dia'),
    );
    await tester.ensureVisible(group);
    await tester.tap(group);
    await settleAfterTap(tester);

    final groceries = find.bySemanticsLabel('Mercado, ver os lançamentos');
    expect(groceries, findsOneWidget);
    await tester.ensureVisible(groceries);
    await tester.tap(groceries);
    await settleAfterTap(tester);
    await tester.pump();

    // A tela de Lançamentos, já com o chip da categoria escolhida.
    expect(find.byType(CajuiRingChart), findsNothing);
    expect(find.widgetWithText(CajuiChip, 'Mercado'), findsOneWidget);
  });
}
