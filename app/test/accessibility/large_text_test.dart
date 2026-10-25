import 'package:cajui/src/app/cajui_app.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/home_navigation.dart';
import '../support/memory_ledger_journal.dart';
import '../support/sample_plan.dart';
import '../support/test_scope.dart';

/// Celular estreito (360 dp) com a fonte do sistema em 130%: as telas
/// principais não podem estourar nem esconder botão (17/10/2026).
Future<void> _open(WidgetTester tester, {double textScale = 1.3}) async {
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
    testWidgets('o Painel cabe, e os alvos de toque têm 48 dp', (tester) async {
      await _open(tester);
      await tester.tap(find.bySemanticsLabel('Painel'));
      await settleAfterTap(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    group('os dois botões de baixo do Painel', () {
      // 24/10/2026: "Novo lançamento" e "Entrou dinheiro" saíam cortados
      // ("Novo lançame…", "Entrou di…"). A fonte do teste é larga demais para
      // conferir corte de texto; aqui vale o desenho: mesma largura, e um
      // sobre o outro quando a fonte do sistema está grande.
      Future<List<Rect>> buttons(WidgetTester tester, double scale) async {
        await _open(tester, textScale: scale);
        await tester.tap(find.bySemanticsLabel('Painel'));
        await settleAfterTap(tester);
        return [
          for (final label in ['Gastei', 'Recebi'])
            tester.getRect(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(CajuiButton),
              ),
            ),
        ];
      }

      testWidgets('com a fonte normal, lado a lado e do mesmo tamanho', (
        tester,
      ) async {
        final [spent, received] = await buttons(tester, 1);

        expect(spent.width, received.width);
        expect(spent.top, received.top);
        expect(spent.left, lessThan(received.left));
      });

      testWidgets('com a fonte em 130%, um sobre o outro, de largura inteira', (
        tester,
      ) async {
        final [spent, received] = await buttons(tester, 1.3);

        expect(spent.width, received.width);
        expect(spent.left, received.left);
        expect(spent.top, lessThan(received.top));
        expect(spent.width, greaterThan(300));
      });
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
