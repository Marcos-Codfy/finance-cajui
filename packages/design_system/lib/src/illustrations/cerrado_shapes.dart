import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// As formas que as três ilustrações do Cerrado dividem: a folha e a pétala.
abstract final class CerradoShapes {
  /// Uma folha de [base] até [tip], com até [width] de cada lado do eixo: a
  /// base cheia e a ponta fina, como as folhas largas do cerrado.
  static Path leaf(Offset base, Offset tip, double width) {
    final axis = tip - base;
    final normal = Offset(-axis.dy, axis.dx) / axis.distance;
    Offset at(double along, double side) =>
        base + axis * along + normal * width * side;
    final (a1, a2) = (at(0.1, 1), at(0.65, 0.8));
    final (b1, b2) = (at(0.65, -0.8), at(0.1, -1));
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(a1.dx, a1.dy, a2.dx, a2.dy, tip.dx, tip.dy)
      ..cubicTo(b1.dx, b1.dy, b2.dx, b2.dy, base.dx, base.dy)
      ..close();
  }

  /// Uma flor de cinco pétalas redondas em volta de [center], com [radius]
  /// de raio e girada de [turn] (em radianos): o ipê visto de frente.
  static void flower(
    Canvas canvas,
    Offset center,
    double radius, {
    required Paint petal,
    required Paint heart,
    double turn = 0,
  }) {
    for (var index = 0; index < 5; index++) {
      final angle = turn + index * 2 * math.pi / 5;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(angle)
        ..drawOval(
          Rect.fromCenter(
            center: Offset(0, -radius * 0.55),
            width: radius * 0.9,
            height: radius * 1.1,
          ),
          petal,
        )
        ..restore();
    }
    canvas.drawCircle(center, radius * 0.28, heart);
  }
}
