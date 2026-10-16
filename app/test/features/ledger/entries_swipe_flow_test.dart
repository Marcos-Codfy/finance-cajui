import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/household_book.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

Future<MemoryLedgerJournal> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal([
    recordedEntry(
      id: 'bakery',
      cents: 1250,
      on: testYesterday,
      description: 'Padaria Pão Quente',
      categoryId: 'bakery',
    ),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal),
      child: const CajuiApp(),
    ),
  );
  await settleAfterTap(tester);
  await openFromHome(tester, 'Lançamentos');
  return journal;
}

Future<void> _swipeLeft(WidgetTester tester) async {
  await tester.drag(find.text('Padaria Pão Quente'), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

void main() {
  group('Lançamentos por dia e deslizando', () {
    testWidgets('o dia vem com o total dele', (tester) async {
      await _open(tester);

      expect(find.textContaining(r'Ontem · R$'), findsOneWidget);
    });

    testWidgets('deslizar para a esquerda some com a linha, e Desfazer traz '
        'de volta sem gravar nada', (tester) async {
      final journal = await _open(tester);

      await _swipeLeft(tester);
      expect(find.text('Padaria Pão Quente'), findsNothing);
      expect(find.text('Lançamento cancelado'), findsOneWidget);
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();

      expect(find.text('Padaria Pão Quente'), findsOneWidget);
      await tester.pump(CajuiDurations.undo);
      final events = await journal.readAll();
      expect(events.whereType<EntryCancelled>(), isEmpty);
    });

    testWidgets('fechada a janela do Desfazer, o cancelamento é gravado', (
      tester,
    ) async {
      final journal = await _open(tester);

      await _swipeLeft(tester);
      await tester.pump(CajuiDurations.undo);
      await tester.pumpAndSettle();

      final events = await journal.readAll();
      expect(events.whereType<EntryCancelled>().single.entryId, 'bakery');
      expect(find.text('Lançamento cancelado'), findsNothing);
    });

    testWidgets('deslizar para a direita abre a correção', (tester) async {
      await _open(tester);

      await tester.drag(find.text('Padaria Pão Quente'), const Offset(600, 0));
      await tester.pumpAndSettle();

      expect(find.text('Corrigir despesa'), findsOneWidget);
    });
  });
}
