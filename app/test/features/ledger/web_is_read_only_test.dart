import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Abre o app como **a web**: sem identidade de aparelho, que é o que a
/// `NoLedgerUplink` representa na raiz de composição (ADR-013).
Future<void> _openAsWeb(WidgetTester tester, {required bool web}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(),
        uplink: web ? const NoLedgerUplink() : null,
      ),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Lançamentos'));
  await tester.pump();
}

void main() {
  group('T-12 · a consulta pela web não convida a lançar', () {
    testWidgets('sem aparelho cadastrado, não há botão de lançar', (
      tester,
    ) async {
      await _openAsWeb(tester, web: true);

      // Tocar em "Lançar" levava ao formulário e só estourava na hora de
      // salvar, porque a consulta não grava. Agora a porta nem aparece.
      expect(find.text('Lançar'), findsNothing);
      expect(find.text('Fotografar'), findsNothing);
      expect(find.text('Da galeria'), findsNothing);
    });

    testWidgets('no celular, o botão de lançar continua lá', (tester) async {
      await _openAsWeb(tester, web: false);

      expect(find.text('Lançar'), findsOneWidget);
    });
  });
}
