import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _open(WidgetTester tester, List<LedgerEvent> events) async {
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal(events)),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('primeiro uso: o painel já é o painel — o gasto do mês, a '
      'sobra que espera a renda, e a porta para lançar', (tester) async {
    await _open(tester, const []);

    expect(find.text('Seu mês começa aqui'), findsNothing);
    expect(find.text('Gasto do mês em dinheiro'), findsOneWidget);
    expect(find.textContaining('Cadastre a renda'), findsOneWidget);
    expect(find.text('Novo lançamento'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Plano do mês'));
    await _settle(tester);

    expect(find.text('Sobra planejada'), findsOneWidget);
  });

  testWidgets('com o plano, o painel responde primeiro quanto dá para gastar '
      'na semana', (tester) async {
    await _open(tester, samplePlanEvents);

    expect(find.text('Setembro'), findsOneWidget);
    expect(find.text('SEMANA DE 14 A 20'), findsOneWidget);
    expect(find.text('Dá para gastar esta semana'), findsOneWidget);
    expect(find.text('Sobra prevista de setembro'), findsOneWidget);
    expect(find.text('49% da renda, em fixos e dívidas'), findsOneWidget);
    expect(find.textContaining('não se soma ao dinheiro'), findsOneWidget);
  });

  testWidgets('RN-604 · sem renda, o painel pede a renda em vez de inventar '
      'proporção', (tester) async {
    await _open(tester, [
      PlanDefined(
        id: 'p',
        setup: samplePlan.withMoney(cashIncome: Money.zero),
      ),
    ]);

    expect(find.textContaining('Cadastre a renda'), findsOneWidget);
    expect(find.textContaining('% da renda'), findsNothing);
    expect(find.text('Renda comprometida'), findsNothing);
  });

  testWidgets('D-UX-22 · mês que não fecha: "faltam", com o que dá para '
      'fazer, e nada de alarme', (tester) async {
    await _open(tester, [
      PlanDefined(
        id: 'p',
        // Sem vale, o mercado inteiro é em dinheiro: o plano pede 2.622,00
        // e a renda é de 2.600,00. Faltam 22,00, e a folga dos variáveis
        // (380,00) cobre.
        setup: samplePlan.withMoney(cashIncome: const Money.fromCents(260000)),
      ),
    ]);

    expect(find.text('Faltam para fechar setembro'), findsOneWidget);
    expect(find.text('R\$${_nbsp}22,00'), findsOneWidget);
    expect(find.textContaining('ajustando os variáveis'), findsOneWidget);
    expect(find.textContaining('!'), findsNothing);
  });

  testWidgets('quando nem os variáveis cobrem, o painel diz isso sem '
      'dramatizar', (tester) async {
    await _open(tester, [
      PlanDefined(
        id: 'p',
        setup: samplePlan.withMoney(cashIncome: const Money.fromCents(190000)),
      ),
    ]);

    expect(find.textContaining('vale rever um fixo'), findsOneWidget);
  });

  testWidgets('UC-ENTRY-01 · antes de lançar, a tela mostra o efeito no '
      'resta da semana', (tester) async {
    await _open(tester, samplePlanEvents);

    await tester.tap(find.text('Novo lançamento'));
    await _settle(tester);
    await tester.enterText(_field('Valor'), '850');
    await tester.enterText(_field('O que foi'), 'Ônibus');
    await tester.tap(find.text('Categoria'));
    await _settle(tester);
    await tester.tap(find.text('Transporte'));
    await _settle(tester);
    await tester.tap(find.text('Por onde foi pago'));
    await _settle(tester);
    await tester.tap(find.text('Pix'));
    await _settle(tester);

    expect(
      find.text('Resta na semana: R\$${_nbsp}168,82 → R\$${_nbsp}160,32'),
      findsOneWidget,
    );
  });

  testWidgets('RN-420 · faixa com mínimo acima do máximo: o texto do catálogo '
      'fica sob o campo', (tester) async {
    await _open(tester, samplePlanEvents);
    await tester.tap(find.bySemanticsLabel('Plano do mês'));
    await _settle(tester);
    await tester.tap(find.text('Transporte'));
    await _settle(tester);

    await tester.enterText(_field('Mínimo do mês'), '90000');
    await tester.tap(find.text('Guardar'));
    await _settle(tester);

    expect(find.textContaining('ficou maior que o máximo'), findsOneWidget);
    expect(find.text('Gasto variável'), findsOneWidget);
  });
}
