import 'package:cajui/src/app/cajui_app.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
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
  testWidgets('cadastrar o cartão, comprar em 3× e ver a fatura: o cartão '
      'aparece só como "por onde foi pago", e a parcela vem com o total '
      'comprometido', (tester) async {
    tester.view.physicalSize = const Size(390, 2600);
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
    await _settle(tester);

    // Cadastro: nome e dias. Não existe campo de número de cartão.
    await _tap(tester, find.bySemanticsLabel('Ajustes'));
    await _tap(tester, find.text('Cartões de crédito'));
    await _tap(tester, find.text('Cadastrar cartão'));
    expect(find.textContaining('úmero do cartão'), findsNothing);
    await tester.enterText(_field('Nome do cartão'), 'Cartão da casa');
    await _tap(tester, find.text('Fecha em'));
    await _tap(tester, find.text('dia 25'));
    await _tap(tester, find.text('Vence em'));
    await _tap(tester, find.text('dia 5'));
    await _tap(tester, find.text('Guardar'));
    expect(find.text('fecha dia 25 · vence dia 5'), findsOneWidget);

    // Compra em 3×, paga no cartão.
    await _tap(tester, find.bySemanticsLabel('Voltar'));
    await _tap(tester, find.bySemanticsLabel('Lançamentos'));
    await _tap(tester, find.text('Lançar'));
    await tester.enterText(_field('Valor'), '96000');
    await tester.enterText(_field('O que foi'), 'Fogão');
    await _tap(tester, find.text('Categoria'));
    await _tap(tester, find.text('Casa'));
    await _tap(tester, find.text('Por onde foi pago'));
    await _tap(tester, find.text('Cartão da casa'));
    await _tap(tester, find.text('Em quantas vezes'));
    await _tap(tester, find.text('3x de R\$${_nbsp}320,00'));

    // RN-313: a parcela nunca aparece sem o total comprometido.
    expect(
      find.textContaining('Total comprometido: R\$${_nbsp}960,00'),
      findsOneWidget,
    );
    // RN-312: compra parcelada não mexe no limite da semana.
    expect(find.textContaining('Resta na semana'), findsNothing);

    await _tap(tester, find.text('Lançar'));
    expect(find.text('Casa · Cartão da casa · hoje'), findsOneWidget);

    // A fatura é calculada: primeira parcela, vencendo em outubro.
    await _tap(tester, find.bySemanticsLabel('Ajustes'));
    await _tap(tester, find.text('Cartões de crédito'));
    await _tap(tester, find.text('Cartão da casa'));
    expect(find.textContaining('vence em 5 de outubro'), findsOneWidget);
    expect(
      find.textContaining(
        'parcela 1 de 3 · ainda comprometido R\$${_nbsp}960,00',
      ),
      findsOneWidget,
    );
    expect(find.text('Registrar pagamento'), findsOneWidget);
  });
}
