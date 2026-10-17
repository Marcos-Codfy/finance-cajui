import 'package:cajui/src/app/cajui_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/home_navigation.dart';
import '../support/memory_ledger_journal.dart';
import '../support/sample_plan.dart';
import '../support/test_scope.dart';

/// Celular estreito (360 dp) com a fonte do sistema em 130%: as telas
/// principais não podem estourar nem esconder botão (17/10/2026).
Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
      child: const CajuiApp(),
    ),
  );
  await settleAfterTap(tester);
}

void main() {
  group('fonte grande (130%) num celular estreito', () {
    testWidgets('o Início cabe, e os alvos de toque têm 48 dp', (tester) async {
      await _open(tester);
      await tester.tap(find.bySemanticsLabel('Início'));
      await settleAfterTap(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    for (final door in ['Lançamentos', 'Meu mês', 'Cartões', 'Dívidas']) {
      testWidgets('$door cabe, e os alvos de toque têm 48 dp', (tester) async {
        await _open(tester);
        await openFromHome(tester, door);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }

    testWidgets('a conversa com a Juju cabe', (tester) async {
      await _open(tester);
      await tester.tap(find.bySemanticsLabel('Conversar'));
      await settleAfterTap(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
