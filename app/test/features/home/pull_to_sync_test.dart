import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/sync_now.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

void main() {
  testWidgets('do topo do Início, puxar para baixo força a sincronização', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var syncs = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
          syncNowProvider.overrideWithValue(() async {
            syncs++;
            return true;
          }),
        ],
        child: const CajuiApp(),
      ),
    );
    await settleAfterTap(tester);
    await tester.tap(find.bySemanticsLabel('Início'));
    await settleAfterTap(tester);

    // A abertura já sincroniza sozinha; conta só o que o puxão acrescenta.
    final before = syncs;
    await tester.drag(
      find.bySemanticsLabel('Meu mês').first,
      const Offset(0, 320),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(syncs, before + 1);
  });
}
