import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

void main() {
  testWidgets('RN-120 · registrar o crédito do vale: o saldo sobe, e nada vira '
      'lançamento nem renda em dinheiro', (tester) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final journal = MemoryLedgerJournal(samplePlanEvents);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(journal: journal),
        child: const CajuiApp(),
      ),
    );
    await _settle(tester);

    await _tap(tester, find.bySemanticsLabel('Plano do mês'));
    await _tap(tester, find.text('Registrar recebimento'));
    await _tap(tester, find.text('No vale alimentação'));

    // No vale não existe "renda do mês × avulsa": é só crédito no saldo.
    expect(find.text('É a renda do mês'), findsNothing);

    await tester.enterText(_field('Quanto entrou'), '60000');
    // O botão só habilita com valor: a tela precisa de um quadro para isso.
    await _settle(tester);
    await _tap(tester, find.text('Registrar'));
    await _tap(tester, find.bySemanticsLabel('Voltar'));

    // 650,00 de saldo + 600,00 de crédito.
    expect(find.text('R\$${_nbsp}1.250,00'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Lançamentos'));
    expect(find.text('Nada lançado ainda'), findsOneWidget);
  });
}
