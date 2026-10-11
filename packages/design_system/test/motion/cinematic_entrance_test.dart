import 'package:design_system/design_system.dart';
import 'package:design_system/src/motion/arrival_pose.dart';
import 'package:design_system/src/motion/stagger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

Widget _scene({CajuiThemeData? theme, Object? replay, bool visible = true}) {
  return host(
    TickerMode(
      enabled: visible,
      child: CajuiCinematicEntrance(
        replayKey: replay,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              CajuiCinematicShot(index: i, child: Text('Bloco $i')),
          ],
        ),
      ),
    ),
    theme: theme,
  );
}

/// O que a tomada [index] aplica neste quadro: opacidade, matriz e se o
/// desfoque está ligado.
(double, Matrix4, bool) _shot(WidgetTester tester, int index) {
  final shot = find.byType(CajuiCinematicShot).at(index);
  T inside<T extends Widget>() => tester.widget<T>(
    find.descendant(of: shot, matching: find.byType(T)).first,
  );
  return (
    inside<Opacity>().opacity,
    inside<Transform>().transform,
    inside<ImageFiltered>().enabled,
  );
}

void main() {
  group('ArrivalPose', () {
    test('parte de longe, de baixo, transparente e fora de foco', () {
      final (pose, blur) = ArrivalPose.of(0, motion: MotionLevel.full);

      expect(pose.opacity, 0);
      expect(pose.scale, closeTo(0.86, 1e-9));
      expect(pose.shift.dy, 28);
      expect(blur, CajuiDepth.arrivalBlur);
    });

    test('chega plana, inteira e nítida', () {
      final (pose, blur) = ArrivalPose.of(1, motion: MotionLevel.full);

      expect(pose.isFlat, isTrue);
      expect(pose.opacity, 1);
      expect(blur, 0);
    });

    test('no lite, a viagem fica e o desfoque sai', () {
      final (pose, blur) = ArrivalPose.of(0, motion: MotionLevel.lite);

      expect(pose.scale, lessThan(1));
      expect(blur, 0);
    });

    test('RNF-A11Y-07 no reduzido, só a opacidade muda', () {
      final (pose, blur) = ArrivalPose.of(0.5, motion: MotionLevel.reduced);

      expect(pose.isFlat, isTrue);
      expect(pose.opacity, inInclusiveRange(0.1, 0.9));
      expect(blur, 0);
    });
  });

  group('staggered', () {
    test('a cascata inteira cabe nos 600 ms: o 6º bloco sai aos 175 ms', () {
      // 5 × 35 ms de intervalo; cada bloco anda os 425 ms restantes.
      expect(staggered(175 / 600, 5), 0);
      expect(staggered(176 / 600, 5), greaterThan(0));
      for (var i = 0; i < 12; i++) {
        expect(staggered(1, i), 1, reason: 'bloco $i');
      }
    });

    test('do 6º bloco em diante, todos chegam juntos', () {
      expect(staggered(0.5, 9), staggered(0.5, 5));
    });
  });

  group('CajuiCinematicEntrance', () {
    testWidgets('RNF-A11Y-08 roda uma vez e termina assentada', (tester) async {
      await tester.pumpWidget(_scene());
      await tester.pump();

      final (opacity, matrix, blurred) = _shot(tester, 0);
      expect(opacity, 0);
      expect(matrix.isIdentity(), isFalse);
      expect(blurred, isTrue);

      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        final (opacity, matrix, blurred) = _shot(tester, i);
        expect(opacity, 1, reason: 'bloco $i');
        expect(matrix.isIdentity(), isTrue, reason: 'bloco $i');
        expect(blurred, isFalse, reason: 'bloco $i');
      }
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a cascata inteira acaba em 600 ms', (tester) async {
      await tester.pumpWidget(_scene());
      await tester.pump();
      await tester.pump(CajuiDurations.slowest);
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('com a chave nova, a entrada roda de novo', (tester) async {
      await tester.pumpWidget(_scene(replay: 1));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_scene(replay: 2));
      await tester.pump();

      expect(_shot(tester, 0).$1, lessThan(1));
      await tester.pumpAndSettle();
      expect(_shot(tester, 0).$1, 1);
    });

    testWidgets('RNF-A11Y-07 no reduzido, só esmaece, junto e curto', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scene(theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced)),
      );
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        final (_, matrix, blurred) = _shot(tester, i);
        expect(matrix.isIdentity(), isTrue);
        expect(blurred, isFalse);
      }
      await tester.pump(CajuiDurations.reducedFade);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('espera a tela estar à vista para começar', (tester) async {
      await tester.pumpWidget(_scene(visible: false));
      await tester.pump(const Duration(seconds: 1));

      expect(_shot(tester, 0).$1, 0);

      await tester.pumpWidget(_scene());
      await tester.pumpAndSettle();
      expect(_shot(tester, 0).$1, 1);
    });

    testWidgets('RNF-A11Y-06 quem ouve acha o bloco desde o primeiro quadro', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_scene());
      await tester.pump();

      expect(find.bySemanticsLabel('Bloco 2'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('no lite, sem desfoque e sem luz', (tester) async {
      await tester.pumpWidget(
        _scene(theme: CajuiThemeData.light(motionLevel: MotionLevel.lite)),
      );
      await tester.pump();

      expect(_shot(tester, 0).$3, isFalse);
      final light = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CajuiCinematicEntrance),
              matching: find.byType(CustomPaint),
            )
            .last,
      );
      expect(light.painter, isNull);
    });

    testWidgets('sem entrada acima, a tomada não mexe no bloco', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const CajuiCinematicShot(child: Text('Sozinho'))),
      );

      expect(
        find.descendant(
          of: find.byType(CajuiCinematicShot),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });
}
