import 'dart:math' as math;

import 'package:design_system/src/components/gauge/water_motion.dart';
import 'package:flutter/widgets.dart';

/// Desenha o pote: vidro, tampa, água e o reflexo.
///
/// Repinta sozinho quando a [water] se mexe, sem reconstruir widget nenhum:
/// a água balançando custa só a pintura de um retângulo pequeno.
class WaterJarPainter extends CustomPainter {
  /// Cria o pintor do pote com as cores do tema em vigor.
  new({
    required this.water,
    required this.liquid,
    required this.glass,
    required this.outline,
    required this.sheen,
  }) : super(repaint: water);

  /// A física da água.
  final WaterMotion water;

  /// A cor da água: `data.water`.
  final Color liquid;

  /// O fundo do pote vazio: `data.track`.
  final Color glass;

  /// O contorno do vidro e da tampa.
  final Color outline;

  /// A luz que bate no vidro e na superfície da água: `brand.sheen`.
  final Color sheen;

  /// De quantos em quantos pixels a superfície é medida: abaixo de 3 a
  /// diferença não se vê; acima de 6 a onda fica facetada.
  static const double _step = 3;
  static const double _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rimHeight = math.max(6, size.height * 0.08).toDouble();
    final body = Rect.fromLTRB(0, rimHeight + 3, size.width, size.height);
    final jar = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(size.width * 0.18),
      topRight: Radius.circular(size.width * 0.18),
      bottomLeft: Radius.circular(size.width * 0.3),
      bottomRight: Radius.circular(size.width * 0.3),
    );
    canvas
      ..drawRRect(jar, Paint()..color = glass)
      ..save()
      ..clipRRect(jar);
    _paintWater(canvas, body.deflate(_stroke));
    _paintShine(canvas, body);
    canvas
      ..restore()
      ..drawRRect(jar, _outlinePaint());
    _paintRim(canvas, size.width, rimHeight);
  }

  Paint _outlinePaint() => Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = _stroke;

  /// A superfície na posição [x]: o nível, a inclinação em torno do centro —
  /// que preserva o volume — e a onda correndo.
  double _surfaceAt(double x, Rect area) {
    final base = area.bottom - water.level * area.height;
    final slope = math.tan(water.angle) * (x - area.center.dx);
    final wave = (x - area.left) / area.width * 2.4 * math.pi + water.phase;
    return base + slope + water.ripple * area.height * math.sin(wave);
  }

  Path _surface(Rect area) {
    final path = Path()..moveTo(area.left, _surfaceAt(area.left, area));
    for (var x = area.left + _step; x < area.right; x += _step) {
      path.lineTo(x, _surfaceAt(x, area));
    }
    return path..lineTo(area.right, _surfaceAt(area.right, area));
  }

  void _paintWater(Canvas canvas, Rect area) {
    if (water.level <= 0.002) return;
    final top = Color.lerp(liquid, sheen, 0.22)!;
    final body = Path.from(_surface(area))
      ..lineTo(area.right, area.bottom + _stroke)
      ..lineTo(area.left, area.bottom + _stroke)
      ..close();
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, liquid],
      ).createShader(area);
    final crest = Paint()
      ..color = sheen.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas
      ..drawPath(body, fill)
      ..drawPath(_surface(area), crest);
  }

  /// O reflexo do vidro: uma faixa vertical à esquerda, que some nas pontas.
  void _paintShine(Canvas canvas, Rect body) {
    final band = Rect.fromLTWH(
      body.left + body.width * 0.14,
      body.top + body.height * 0.12,
      body.width * 0.08,
      body.height * 0.62,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          sheen.withValues(alpha: 0),
          sheen.withValues(alpha: 0.4),
          sheen.withValues(alpha: 0),
        ],
      ).createShader(band);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(band.width / 2)),
      paint,
    );
  }

  void _paintRim(Canvas canvas, double width, double height) {
    final rim = RRect.fromRectAndRadius(
      Rect.fromLTRB(width * 0.12, 0, width * 0.88, height),
      Radius.circular(height / 2),
    );
    canvas
      ..drawRRect(rim, Paint()..color = glass)
      ..drawRRect(rim, _outlinePaint());
  }

  @override
  bool shouldRepaint(WaterJarPainter old) =>
      old.water != water ||
      old.liquid != liquid ||
      old.glass != glass ||
      old.outline != outline ||
      old.sheen != sheen;
}
