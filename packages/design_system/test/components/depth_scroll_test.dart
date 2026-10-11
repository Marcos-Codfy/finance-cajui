import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/depth/drum_pose.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _screen = Size(360, 640);

/// Seções de 200 de altura numa tela de 640: com a margem de 20, as três
/// primeiras ficam inteiras (20 a 620), e a 4ª sai cortada pela borda.
Widget _scroll({
  CajuiThemeData? theme,
  bool systemReduces = false,
  double textScale = 1,
  ScrollController? controller,
  VoidCallback? onTap,
}) {
  final body = MediaQuery(
    data: MediaQueryData(
      size: _screen,
      disableAnimations: systemReduces,
      textScaler: TextScaler.linear(textScale),
    ),
    child: SizedBox.fromSize(
      size: _screen,
      child: CajuiDepthScroll(
        controller: controller,
        children: [for (var i = 0; i < 8; i++) _section(i, onTap: onTap)],
      ),
    ),
  );
  return host(body, theme: theme);
}

/// A seção 1 é a que responde ao toque.
Widget _section(int index, {VoidCallback? onTap}) => SizedBox(
  height: 200,
  child: GestureDetector(
    onTap: index == 1 ? onTap : null,
    child: Text('Seção $index'),
  ),
);

Future<void> _screenSize(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A lente da matriz que leva a seção à tela: diferente de zero só quando
/// a seção está curvada.
double _lens(WidgetTester tester, String label) => tester
    .renderObject<RenderBox>(find.text(label))
    .getTransformTo(null)
    .entry(3, 2);

void main() {
  group('DrumPose', () {
    test(
      'RNF-PERF-01 item inteiro à vista fica plano, com matriz identidade',
      () {
        final pose = DrumPose.of(top: 220, bottom: 420, extent: 640);

        expect(pose.isFlat, isTrue);
        expect(pose.alpha, 255);
        expect(pose.matrix(const Size(320, 200)).isIdentity(), isTrue);
      },
    );

    test('quem entra por baixo vem deitado, menor e esmaecido', () {
      // Faixa da borda: 640 × 0,32 = 204,8; a seção de 200 é toda faixa.
      final pose = DrumPose.of(top: 540, bottom: 740, extent: 640);

      expect(pose.tilt, greaterThan(0));
      expect(pose.scale, lessThan(1));
      expect(pose.opacity, lessThan(1));
      expect(pose.pivot, Alignment.topCenter);
    });

    test('quem sai por cima recua, preso pela borda de baixo', () {
      final pose = DrumPose.of(top: -120, bottom: 80, extent: 640);

      expect(pose.tilt, lessThan(0));
      expect(pose.scale, lessThan(1));
      expect(pose.shift.dy, greaterThan(0));
      expect(pose.pivot, Alignment.bottomCenter);
    });

    test('a seção no alto da tela, sem ter rolado, fica plana', () {
      expect(DrumPose.of(top: 0, bottom: 60, extent: 640).isFlat, isTrue);
    });

    test('bloco comprido fica plano enquanto sobra mais que a faixa', () {
      // 900 de altura, 400 à vista: mais que os 204,8 da faixa.
      final pose = DrumPose.of(top: -500, bottom: 400, extent: 640);

      expect(pose.isFlat, isTrue);
    });

    test('sem esmaecer, a curva fica e a opacidade não muda', () {
      final pose = DrumPose.of(
        top: 540,
        bottom: 740,
        extent: 640,
        fades: false,
      );

      expect(pose.tilt, greaterThan(0));
      expect(pose.opacity, 1);
    });
  });

  group('CajuiDepthScroll', () {
    testWidgets('RNF-PERF-01 só a seção cortada pela borda curva', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(_scroll());

      expect(_lens(tester, 'Seção 0'), 0);
      expect(_lens(tester, 'Seção 2'), 0);
      expect(_lens(tester, 'Seção 3'), isNot(0));
    });

    testWidgets('rolar até a seção a deixa plana, sem montar nada de novo', (
      tester,
    ) async {
      await _screenSize(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_scroll(controller: controller));
      final section = tester.element(find.text('Seção 3'));

      controller.jumpTo(240);
      await tester.pump();

      // A 3ª vai de 380 a 580; a 1ª, de -20 a 180, já saindo por cima.
      expect(_lens(tester, 'Seção 3'), 0);
      expect(_lens(tester, 'Seção 1'), isNot(0));
      expect(tester.element(find.text('Seção 3')), same(section));
    });

    testWidgets('RNF-A11Y-07 no reduzido do tema, nada curva', (tester) async {
      await _screenSize(tester);
      await tester.pumpWidget(
        _scroll(theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced)),
      );

      expect(_lens(tester, 'Seção 3'), 0);
    });

    testWidgets('RNF-A11Y-07 o pedido do sistema vale mesmo com tema cheio', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(_scroll(systemReduces: true));

      expect(_lens(tester, 'Seção 3'), 0);
    });

    testWidgets('no lite a borda curva, mas não esmaece', (tester) async {
      await _screenSize(tester);
      await tester.pumpWidget(
        _scroll(theme: CajuiThemeData.light(motionLevel: MotionLevel.lite)),
      );

      expect(_lens(tester, 'Seção 3'), isNot(0));
      expect(
        tester.layers.whereType<OpacityLayer>().where((l) => l.alpha! < 255),
        isEmpty,
      );
    });

    testWidgets('o toque chega à seção que está à vista', (tester) async {
      await _screenSize(tester);
      var taps = 0;
      await tester.pumpWidget(_scroll(onTap: () => taps++));

      await tester.tap(find.text('Seção 1'));

      expect(taps, 1);
    });

    testWidgets('RNF-A11Y-04 em 360 de largura e fonte a 200%, nada estoura', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(_scroll(textScale: 2));
      await tester.drag(find.byType(CajuiDepthScroll), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('CajuiParallax', () {
    /// A camada é posta a 520 do alto, abaixo do centro (320) de uma tela de
    /// 640.
    Widget layered({bool systemReduces = false}) => host(
      MediaQuery(
        data: MediaQueryData(size: _screen, disableAnimations: systemReduces),
        child: SizedBox.fromSize(
          size: _screen,
          child: ListView(
            children: const [
              SizedBox(height: 520),
              CajuiParallax(factor: 0.2, child: Text('Fundo')),
              SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );

    double paintedTop(WidgetTester tester) => tester
        .renderObject<RenderBox>(find.text('Fundo'))
        .localToGlobal(Offset.zero)
        .dy;

    testWidgets('abaixo do centro, a camada aparece acima do lugar', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(layered());

      // 0,2 × (uns 530 − 320) ≈ 42 px para cima.
      expect(paintedTop(tester), lessThan(500));
      expect(paintedTop(tester), greaterThan(460));
    });

    testWidgets('RNF-A11Y-07 no reduzido, a camada fica onde está', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(layered(systemReduces: true));

      expect(paintedTop(tester), 520);
    });
  });

  test('SpacePose em repouso é identidade exata, sem lente', () {
    expect(SpacePose.rest.local.isIdentity(), isTrue);
    // Girada, a lente entra: o termo de perspectiva, pelo cosseno do giro.
    expect(
      const SpacePose(turn: 0.3).local.entry(3, 2),
      closeTo(CajuiDepth.perspective * math.cos(0.3), 1e-9),
    );
  });
}
