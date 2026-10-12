import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

Widget _scene(
  int arrival, {
  required CajuiFeedback feedback,
  MotionLevel motion = MotionLevel.full,
}) => host(
  CajuiGlassArrival(
    arrival: arrival,
    child: const SizedBox(width: 200, height: 120, child: Text(r'R$ 1.312,40')),
  ),
  theme: CajuiThemeData.light(motionLevel: motion),
  feedback: feedback,
);

/// A escala do bloco neste quadro, no eixo x (o z fica sempre em 1).
double _scale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(CajuiGlassArrival),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .entry(0, 0);

void main() {
  group('A chegada pelo widget da tela inicial', () {
    testWidgets('sem chegada, o bloco fica parado e calado', (tester) async {
      final feedback = RecordingFeedback();
      await tester.pumpWidget(_scene(0, feedback: feedback));

      expect(_scale(tester), 1);
      expect(feedback.calls, isEmpty);
      expect(find.text(r'R$ 1.312,40'), findsOneWidget);
    });

    testWidgets('cada toque no widget é uma chegada: o pop do card, o bloco '
        'menor no começo e no tamanho certo no fim, uma vez só', (
      tester,
    ) async {
      final feedback = RecordingFeedback();
      await tester.pumpWidget(_scene(0, feedback: feedback));

      await tester.pumpWidget(_scene(1, feedback: feedback));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_scale(tester), lessThan(0.95));
      expect(feedback.calls, ['cardTapped']);

      await tester.pump(CajuiDurations.slowest);
      expect(_scale(tester), 1);

      // A tela se redesenha com a mesma chegada: nada toca de novo.
      await tester.pumpWidget(_scene(1, feedback: feedback));
      await tester.pump(CajuiDurations.slowest);
      expect(feedback.calls, ['cardTapped']);

      await tester.pumpWidget(_scene(2, feedback: feedback));
      await tester.pump(CajuiDurations.slowest);
      expect(feedback.calls, ['cardTapped', 'cardTapped']);
    });

    testWidgets('o app aberto a frio pelo widget já nasce chegando', (
      tester,
    ) async {
      final feedback = RecordingFeedback();
      await tester.pumpWidget(_scene(1, feedback: feedback));
      await tester.pump(const Duration(milliseconds: 16));

      expect(feedback.calls, ['cardTapped']);
      expect(_scale(tester), lessThan(0.95));
    });

    testWidgets('RNF-A11Y-08 · no movimento reduzido, nada encolhe: só o véu '
        'se desfaz, em 120 ms', (tester) async {
      final feedback = RecordingFeedback();
      await tester.pumpWidget(
        _scene(0, feedback: feedback, motion: MotionLevel.reduced),
      );

      await tester.pumpWidget(
        _scene(1, feedback: feedback, motion: MotionLevel.reduced),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(_scale(tester), 1);

      await tester.pump(CajuiDurations.reducedFade);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
