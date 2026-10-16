import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

Future<ProviderContainer> _openMoneyIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
      child: const CajuiApp(),
    ),
  );
  await settleAfterTap(tester);
  await tester.tap(find.bySemanticsLabel('Início'));
  await settleAfterTap(tester);
  await tester.tap(find.text('Entrou dinheiro'));
  await settleAfterTap(tester);
  return ProviderScope.containerOf(tester.element(find.byType(CajuiApp)));
}

void main() {
  group('Entrou dinheiro, do Início', () {
    testWidgets('o saldo que já estava na conta entra com o nome dele', (
      tester,
    ) async {
      final scope = await _openMoneyIn(tester);

      expect(find.text('Registrar recebimento'), findsOneWidget);
      await tester.enterText(_field('Quanto entrou'), '30000');
      await tester.tap(find.text('Saldo da conta'));
      await settleAfterTap(tester);
      await tester.tap(find.text('Registrar'));
      await settleAfterTap(tester);

      final receipt = scope.read(ledgerProvider).value!.receipts.last;
      expect(receipt.note, 'Saldo da conta');
      expect(receipt.isOneOff, isTrue);
    });

    testWidgets('o extra leva o nome que a pessoa escreveu', (tester) async {
      final scope = await _openMoneyIn(tester);

      await tester.enterText(_field('Quanto entrou'), '12000');
      await tester.enterText(_field('O que foi (opcional)'), 'Venda do sofá');
      await tester.pump();
      await tester.tap(find.text('Registrar'));
      await settleAfterTap(tester);

      expect(
        scope.read(ledgerProvider).value!.receipts.last.note,
        'Venda do sofá',
      );
    });
  });
}
