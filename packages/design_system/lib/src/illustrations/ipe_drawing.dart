import 'package:design_system/src/illustrations/cerrado_palette.dart';
import 'package:design_system/src/illustrations/cerrado_shapes.dart';
import 'package:flutter/widgets.dart';

/// O galho de ipê-amarelo em flor, sem folha — o ipê floresce na seca, de
/// galho nu —, com dois botões e uma pétala caindo.
abstract final class IpeDrawing {
  /// As flores: centro, raio e giro de cada uma.
  static const _flowers = [
    (Offset(300, 150), 48.0, 0.2),
    (Offset(366, 262), 40.0, 0.7),
    (Offset(206, 252), 38.0, -0.3),
    (Offset(262, 206), 30.0, 0.5),
  ];

  /// Os botões que ainda vão abrir.
  static const _buds = [(Offset(340, 104), 12.0), (Offset(402, 226), 10.0)];

  /// Pinta o galho em [canvas], que já está na grade de 512.
  ///
  /// As flores pesam para a direita do galho: o desenho anda um pouco para
  /// a esquerda, para o peso ficar no meio do disco.
  static void paint(Canvas canvas, CerradoPalette palette) {
    canvas
      ..save()
      ..translate(-24, 10);
    _paintBranch(canvas, palette);
    final petal = Paint()..color = palette.petal;
    final heart = Paint()..color = palette.heart;
    for (final (center, radius, turn) in _flowers) {
      CerradoShapes.flower(
        canvas,
        center,
        radius,
        petal: petal,
        heart: heart,
        turn: turn,
      );
    }
    for (final (center, radius) in _buds) {
      canvas.drawCircle(center, radius, petal);
    }
    _paintFallingPetal(canvas, petal);
    canvas.restore();
  }

  /// O galho principal, de baixo para o alto, e dois ramos. Os ramos nascem
  /// em pontos da própria curva do galho (t = 0,35 e t = 0,5), para não
  /// sobrar toco por fora dele.
  static void _paintBranch(Canvas canvas, CerradoPalette palette) {
    final wood = Paint()
      ..color = palette.wood
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(170, 468)
          ..cubicTo(200, 380, 250, 270, 300, 150),
        wood..strokeWidth = 14,
      )
      ..drawPath(
        Path()
          ..moveTo(228, 321)
          ..quadraticBezierTo(300, 300, 366, 262),
        wood..strokeWidth = 9,
      )
      ..drawLine(const Offset(208, 368), const Offset(206, 252), wood);
  }

  /// Uma pétala solta, a caminho do chão.
  static void _paintFallingPetal(Canvas canvas, Paint petal) => canvas
    ..save()
    ..translate(372, 396)
    ..rotate(0.8)
    ..drawOval(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 30),
      petal,
    )
    ..restore();
}
