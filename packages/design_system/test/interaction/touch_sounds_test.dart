import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

/// Monta [child] com uma resposta que anota o que foi pedido.
Future<RecordingFeedback> _hosted(WidgetTester tester, Widget child) async {
  final feedback = RecordingFeedback();
  await tester.pumpWidget(host(child, feedback: feedback));
  return feedback;
}

void main() {
  group('cada família de controle tem o seu som', () {
    testWidgets('botão de ação: o clique', (tester) async {
      final feedback = await _hosted(
        tester,
        CajuiButton(label: 'Lançar', onPressed: () {}),
      );

      await tester.tap(find.text('Lançar'));

      expect(feedback.calls, ['tap']);
    });

    testWidgets('card e linha de lista: o pop', (tester) async {
      final feedback = await _hosted(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CajuiCard(
              onPressed: () {},
              semanticLabel: 'Sobra',
              child: const Text('Sobra'),
            ),
            CajuiListRow(
              title: 'Meu mês',
              onPressed: () {},
              semanticLabel: 'Meu mês',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Sobra'));
      await tester.tap(find.text('Meu mês'));

      expect(feedback.calls, ['cardTapped', 'cardTapped']);
    });

    testWidgets('opção de uma lista: o pop, como a linha', (tester) async {
      final feedback = await _hosted(
        tester,
        CajuiOptionList<String>(
          options: const ['Pix', 'Débito'],
          labelOf: (option) => option,
          onSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Débito'));

      expect(feedback.calls, ['cardTapped']);
    });

    testWidgets('chip: o som da chave, ligando e desligando', (tester) async {
      var selected = false;
      final feedback = RecordingFeedback();
      Widget chip() => host(
        CajuiChip(
          label: 'Mercado',
          selected: selected,
          onSelected: (value) => selected = value,
        ),
        feedback: feedback,
      );
      await tester.pumpWidget(chip());

      await tester.tap(find.text('Mercado'));
      await tester.pumpWidget(chip());
      await tester.tap(find.text('Mercado'));

      expect(feedback.calls, ['toggle:true', 'toggle:false']);
    });
  });

  group('teclas', () {
    testWidgets('cada tecla digitada no campo soa', (tester) async {
      final feedback = await _hosted(
        tester,
        const CajuiTextField(label: 'Descrição'),
      );

      await tester.enterText(find.byType(EditableText), 'pão');

      expect(feedback.calls, ['keyTyped']);
    });

    testWidgets('texto posto pelo app não soa: só o que a pessoa digita', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final feedback = await _hosted(
        tester,
        CajuiTextField(label: 'Valor', controller: controller),
      );

      controller.text = '162,10';
      await tester.pump();

      expect(feedback.calls, isEmpty);
    });
  });
}
