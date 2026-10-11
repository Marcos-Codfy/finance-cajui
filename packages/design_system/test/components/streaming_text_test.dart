import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _answer =
    r'Dá para gastar R$ 212,00 até domingo. A conta de luz vence na '
    'quinta e já está separada.';

Widget _text(String text, {CajuiThemeData? theme, VoidCallback? onDone}) {
  return host(
    SizedBox(width: 300, child: CajuiStreamingText(text, onDone: onDone)),
    theme: theme,
  );
}

/// A opacidade de cada palavra, na ordem.
List<double> _alphas(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text));
  return [
    for (final span in (text.textSpan! as TextSpan).children!)
      (span as TextSpan).style!.color!.a,
  ];
}

void main() {
  group('CajuiStreamingText', () {
    testWidgets('RNF-A11Y-12 o leitor de tela recebe o texto inteiro, já', (
      tester,
    ) async {
      await tester.pumpWidget(_text(_answer));

      expect(find.bySemanticsLabel(_answer), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('aparece palavra por palavra, no lugar certo desde o início', (
      tester,
    ) async {
      await tester.pumpWidget(_text(_answer));
      await tester.pump(const Duration(milliseconds: 90));

      final early = _alphas(tester);
      expect(early.first, greaterThan(0));
      expect(early.last, 0);
      // As palavras que faltam já ocupam o lugar: o balão não muda de altura.
      final before = tester.getSize(find.byType(CajuiStreamingText));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(CajuiStreamingText)), before);
      expect(_alphas(tester), everyElement(1));
    });

    testWidgets('RNF-A11Y-08 resposta longa termina em no máximo 4 s', (
      tester,
    ) async {
      final long = List.filled(400, 'palavra').join(' ');
      await tester.pumpWidget(_text(long));
      await tester.pump();

      await tester.pump(CajuiDurations.streamCap);
      // Um quadro a mais: a animação só se dá por terminada depois do fim.
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_alphas(tester).last, 1);
    });

    testWidgets('um toque mostra tudo e avisa que terminou', (tester) async {
      var done = 0;
      await tester.pumpWidget(_text(_answer, onDone: () => done++));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(CajuiStreamingText));
      await tester.pump();

      expect(_alphas(tester), everyElement(1));
      expect(done, 1);
    });

    testWidgets('RNF-A11Y-07 no movimento reduzido nasce pronto', (
      tester,
    ) async {
      var done = 0;
      final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);
      await tester.pumpWidget(
        _text(_answer, theme: reduced, onDone: () => done++),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(_alphas(tester), everyElement(1));
      expect(done, 1);
    });

    testWidgets('texto que cresce pelo fim não apaga o que já apareceu', (
      tester,
    ) async {
      const start = r'Dá para gastar R$ 212,00 até domingo.';
      await tester.pumpWidget(_text(start));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_text('$start A conta de luz vence na quinta.'));
      await tester.pump();

      final alphas = _alphas(tester);
      expect(alphas.take(6), everyElement(1));
      expect(alphas.last, lessThan(1));
      await tester.pumpAndSettle();
    });

    testWidgets('no balão, o assistente fala a resposta inteira de uma vez', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const CajuiChatBubble(_answer, streamed: true)),
      );

      expect(find.bySemanticsLabel('Cajui: $_answer'), findsOneWidget);
      expect(find.byType(CajuiStreamingText), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
