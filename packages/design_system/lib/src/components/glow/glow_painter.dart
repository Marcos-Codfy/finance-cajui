import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Pinta o brilho em volta de um bloco: o halo e, durante a festa, as
/// faíscas de capim dourado subindo.
///
/// O halo é feito de anéis concêntricos que vão sumindo, e não de desfoque:
/// o nível `lite` proíbe desfoque, e anéis custam quase nada em qualquer
/// aparelho.
class GlowPainter extends CustomPainter {
  /// Cria o pintor.
  const new({
    required this.presence,
    required this.bloom,
    required this.halo,
    required this.spark,
    required this.radius,
  });

  /// Quanto do halo está presente, de 0 a 1.
  final double presence;

  /// Em que ponto está a festa, de 0 a 1; `null` sem festa.
  final double? bloom;

  /// A cor do halo: a da sobra.
  final Color halo;

  /// A cor das faíscas: o capim dourado.
  final Color spark;

  /// O raio de canto do bloco que brilha.
  final BorderRadius radius;

  /// Os anéis do halo: quanto cada um se afasta e quanto aparece. Seis
  /// anéis de 3 px, a cada 2,5 px, se sobrepõem e somem num degradê — com
  /// menos, eles se leem como bordas, e o brilho vira moldura.
  static const _rings = [
    (1.5, 0.13),
    (4.0, 0.1),
    (6.5, 0.07),
    (9.0, 0.045),
    (11.5, 0.025),
    (14.0, 0.012),
  ];

  /// Onde nascem as faíscas, em fração do bloco, e quando cada uma começa.
  /// Fixas, e não sorteadas: a festa é sempre a mesma, e o teste também.
  static const _sparks = [
    (0.12, 0.02, 0.0),
    (0.38, -0.02, 0.08),
    (0.71, 0.03, 0.04),
    (0.94, 0.28, 0.14),
    (0.05, 0.62, 0.18),
    (0.96, 0.78, 0.1),
  ];

  /// A intensidade do halo na festa: sobe rápido a 1,8 e assenta em 1.
  static double intensityAt(double? bloom) {
    if (bloom == null) return 1;
    if (bloom < 0.35) return 1.8 * Curves.easeOut.transform(bloom / 0.35);
    final settle = Curves.easeInOut.transform((bloom - 0.35) / 0.65);
    return 1.8 - 0.8 * settle;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (presence <= 0) return;
    final block = radius.toRRect(Offset.zero & size);
    final strength = presence * intensityAt(bloom);
    for (final (spread, alpha) in _rings) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = halo.withValues(alpha: math.min(1, alpha * strength));
      canvas.drawRRect(block.inflate(spread), ring);
    }
    final party = bloom;
    if (party != null) _paintSparks(canvas, size, party);
  }

  void _paintSparks(Canvas canvas, Size size, double party) {
    for (final (x, y, delay) in _sparks) {
      final life = ((party - delay) / 0.7).clamp(0, 1).toDouble();
      if (life <= 0 || life >= 1) continue;
      final fade = math.sin(math.pi * life);
      final center = Offset(x * size.width, y * size.height - 16 * life);
      final paint = Paint()..color = spark.withValues(alpha: fade);
      canvas.drawPath(_star(center, 3 + 3 * fade), paint);
    }
  }

  /// Uma estrela de quatro pontas, a forma de um brilho de luz.
  static Path _star(Offset center, double reach) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final distance = i.isEven ? reach : reach * 0.32;
      final point = center + Offset.fromDirection(angle, distance);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(GlowPainter old) =>
      old.presence != presence ||
      old.bloom != bloom ||
      old.halo != halo ||
      old.spark != spark ||
      old.radius != radius;
}
