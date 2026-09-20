import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Pinta o cajuí em volume macio: o ícone-herói da marca.
///
/// A geometria é a mesma do símbolo (`tool/brand/build_logo.py`), numa grade
/// de 512: o fruto em pera e a castanha em arco que lê como "C". O volume vem
/// de gradientes radiais e de brilhos desfocados — matéria fosca, uma luz de
/// cima à esquerda, sombra de contato tingida de castanha, nunca preta.
///
/// É vetor: escala para qualquer tamanho sem pesar no pacote do app.
class HeroFruitPainter extends CustomPainter {
  /// Cria o pintor. [lift] de 0 a 1 afasta o fruto do chão e encolhe a
  /// sombra, para a animação de flutuar.
  const new({this.lift = 0});

  /// Quanto o fruto está erguido, de 0 (no chão) a 1.
  final double lift;

  static const _grid = 512.0;
  static const double _tilt = -14 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.shortestSide / _grid);
    _paintGroundShadow(canvas);
    canvas
      ..translate(0, -lift * 14)
      ..translate(256, 256)
      ..rotate(_tilt)
      ..translate(-256, -256);
    _paintNut(canvas);
    _paintFruit(canvas);
  }

  void _paintGroundShadow(Canvas canvas) {
    final spread = 128 - lift * 22;
    final paint = Paint()
      ..color = const Color(0xFF2A1D17).withValues(alpha: 0.28 - lift * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(262, 474),
        width: spread * 2,
        height: 30,
      ),
      paint,
    );
  }

  void _paintNut(Canvas canvas) {
    final arc = Rect.fromCircle(center: const Offset(256, 352), radius: 64);
    const start = -55 * math.pi / 180;
    const sweep = -250 * math.pi / 180;
    final body = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6B4A3A), Color(0xFF3A271E), Color(0xFF1D130E)],
      ).createShader(arc.inflate(30));
    canvas.drawArc(arc, start, sweep, false, body);
    final gloss = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x99C9A58F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawArc(arc.inflate(2), -2.6, -0.9, false, gloss);
  }

  void _paintFruit(Canvas canvas) {
    final fruit = _fruitPath();
    final bounds = fruit.getBounds();
    final body = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.28, -0.48),
        radius: 0.95,
        colors: [
          Color(0xFFFFE08A),
          Color(0xFFF8A63C),
          Color(0xFFE8612B),
          Color(0xFFA92E12),
        ],
        stops: [0, 0.32, 0.68, 1],
      ).createShader(bounds);
    canvas.drawPath(fruit, body);
    _paintHighlights(canvas);
  }

  void _paintHighlights(Canvas canvas) {
    final soft = Paint()
      ..color = const Color(0x80FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(230, 116), width: 30, height: 68),
        soft,
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(222, 98), width: 10, height: 20),
        Paint()..color = const Color(0xD9FFFFFF),
      );
  }

  /// A pera de pescoço estreito e base cheia: o que separa um cajuí de uma
  /// gota. Mesmos pontos de controle do símbolo da marca.
  Path _fruitPath() {
    return Path()
      ..moveTo(256, 52)
      ..cubicTo(284, 52, 304, 72, 308, 104)
      ..cubicTo(314, 150, 352, 168, 352, 210)
      ..cubicTo(352, 248, 310, 270, 256, 270)
      ..cubicTo(202, 270, 160, 248, 160, 210)
      ..cubicTo(160, 168, 198, 150, 204, 104)
      ..cubicTo(208, 72, 228, 52, 256, 52)
      ..close();
  }

  @override
  bool shouldRepaint(HeroFruitPainter oldDelegate) => lift != oldDelegate.lift;
}
