import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('CajuiButton', () {
    testWidgets('dispara ao toque e pede o som de toque', (tester) async {
      var pressed = 0;
      final feedback = RecordingFeedback();
      await tester.pumpWidget(
        host(
          CajuiButton(label: 'Lançar', onPressed: () => pressed++),
          feedback: feedback,
        ),
      );

      await tester.tap(find.text('Lançar'));

      expect(pressed, 1);
      expect(feedback.calls, ['tap']);
    });

    testWidgets('desabilitado não dispara e diz isso ao leitor de tela', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const CajuiButton(label: 'Lançar', onPressed: null)),
      );

      await tester.tap(find.text('Lançar'), warnIfMissed: false);

      final data = tester.getSemantics(find.bySemanticsLabel('Lançar'));
      expect(data.flagsCollection.isEnabled, isNot(true));
      handle.dispose();
    });

    testWidgets('carregando mantém a largura e não dispara de novo', (
      tester,
    ) async {
      var pressed = 0;
      Widget button({required bool loading}) => host(
        CajuiButton(
          label: 'Ver os ajustes',
          loading: loading,
          onPressed: () => pressed++,
        ),
      );

      await tester.pumpWidget(button(loading: false));
      final idle = tester.getSize(find.byType(CajuiButton));
      await tester.pumpWidget(button(loading: true));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(CajuiButton));

      expect(tester.getSize(find.byType(CajuiButton)), idle);
      expect(pressed, 0);
      expect(find.byType(CajuiLoadingDots), findsOneWidget);
    });

    testWidgets('ativa por teclado com Enter e com espaço', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(CajuiButton(label: 'Lançar', onPressed: () => pressed++)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      // A troca de foco só vale no quadro seguinte.
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(pressed, 2);
      expect(find.byType(FocusRing), findsOneWidget);
    });

    testWidgets('RNF-A11Y-05 o alvo tem 48 dp mesmo no tamanho compacto', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CajuiButton(
            label: 'Ok',
            size: CajuiButtonSize.compact,
            onPressed: () {},
          ),
        ),
      );

      final target = tester.getSize(find.byType(CajuiPressable));
      expect(target.height, greaterThanOrEqualTo(48));
      expect(target.width, greaterThanOrEqualTo(48));
    });
  });

  group('CajuiChip', () {
    testWidgets('alterna e marca o selecionado também com ícone', (
      tester,
    ) async {
      bool? received;
      Widget chip({required bool selected}) => host(
        CajuiChip(
          label: 'Transporte',
          selected: selected,
          onSelected: (value) => received = value,
        ),
      );

      await tester.pumpWidget(chip(selected: false));
      expect(find.byType(CajuiIcon), findsNothing);
      await tester.tap(find.text('Transporte'));
      expect(received, isTrue);

      await tester.pumpWidget(chip(selected: true));
      expect(find.byType(CajuiIcon), findsOneWidget);
    });
  });

  group('CajuiSwitch', () {
    testWidgets('alterna, avisa o som e expõe o estado à semântica', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final feedback = RecordingFeedback();
      bool? received;
      await tester.pumpWidget(
        host(
          CajuiSwitch(
            value: false,
            semanticLabel: 'Sons do app',
            onChanged: (value) => received = value,
          ),
          feedback: feedback,
        ),
      );

      await tester.tap(find.byType(CajuiSwitch));

      expect(received, isTrue);
      expect(feedback.calls, ['toggle:true']);
      final data = tester.getSemantics(find.bySemanticsLabel('Sons do app'));
      expect(data.flagsCollection.isToggled, isNot(true));
      handle.dispose();
    });
  });
}
