import 'dart:math' as math;

import 'package:design_system/src/illustrations/cerrado_palette.dart';
import 'package:design_system/src/illustrations/cerrado_shapes.dart';
import 'package:flutter/widgets.dart';

/// O cajuí leve: a geometria do símbolo da marca (`build_logo.py`), chapada,
/// com uma folha no pé do fruto.
///
/// Desenha na grade de 512 do símbolo, já encolhida para caber no disco.
abstract final class CashewDrawing {
  static const double _tilt = -14 * math.pi / 180;

  /// Pinta o cajuí em [canvas], que já está na grade de 512.
  static void paint(Canvas canvas, CerradoPalette palette) {
    canvas
      ..save()
      ..translate(256, 270)
      ..scale(0.78)
      ..rotate(_tilt)
      ..translate(-256, -250);
    _paintLeaf(canvas, palette);
    _paintNut(canvas, palette);
    _paintFruit(canvas, palette);
    canvas.restore();
  }

  /// A folha que sai do pé do fruto, para a direita.
  static void _paintLeaf(Canvas canvas, CerradoPalette palette) {
    canvas.drawPath(
      CerradoShapes.leaf(const Offset(262, 60), const Offset(352, -8), 34),
      Paint()..color = palette.leaf,
    );
  }

  /// A castanha em arco, aberta para a direita: lê como castanha e como "C".
  static void _paintNut(Canvas canvas, CerradoPalette palette) {
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(256, 352), radius: 64),
      -55 * math.pi / 180,
      -250 * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 56
        ..strokeCap = StrokeCap.round
        ..color = palette.wood,
    );
  }

  static void _paintFruit(Canvas canvas, CerradoPalette palette) {
    final fruit = _fruitPath();
    canvas
      ..drawPath(
        fruit,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(-0.5, -1),
            end: const Alignment(0.5, 1),
            colors: palette.fruit,
          ).createShader(fruit.getBounds()),
      )
      ..save()
      ..translate(232, 112)
      ..rotate(12 * math.pi / 180)
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: 26, height: 60),
        Paint()..color = palette.sheen.withValues(alpha: 0.3),
      )
      ..restore();
  }

  /// A pera de pescoço estreito e base cheia, com os pontos do símbolo.
  static Path _fruitPath() => Path()
    ..moveTo(256, 52)
    ..cubicTo(284, 52, 304, 72, 308, 104)
    ..cubicTo(314, 150, 352, 168, 352, 210)
    ..cubicTo(352, 248, 310, 270, 256, 270)
    ..cubicTo(202, 270, 160, 248, 160, 210)
    ..cubicTo(160, 168, 198, 150, 204, 104)
    ..cubicTo(208, 72, 228, 52, 256, 52)
    ..close();
}
