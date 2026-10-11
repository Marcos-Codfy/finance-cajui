import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:design_system/src/tokens/semantic/brand_colors.dart';
import 'package:flutter/widgets.dart';

/// A varredura de luz da entrada cinematográfica: uma faixa macia que cruza
/// a tela uma vez, na diagonal, enquanto os blocos assentam.
///
/// É o reflexo de quando a câmera para: aparece, passa e some. No centro da
/// faixa, a luz não passa de `BrandColors.sheenOverText` — a mesma regra do
/// brilho do cartão, para nenhum texto perder contraste nem por um quadro
/// além do que já foi medido.
class LightSweepPainter extends CustomPainter {
  /// Pinta a faixa conforme [progress] da entrada, com o miolo em [light] e
  /// as bordas aquecidas por [warmth].
  new({required this.progress, required this.light, required this.warmth})
    : super(repaint: progress);

  /// O relógio da entrada, de 0 a 1.
  final Animation<double> progress;

  /// A cor da luz: `brand.sheen`.
  final Color light;

  /// O tom das bordas da faixa: `brand.gold`, o capim dourado.
  final Color warmth;

  /// A luz só cruza na segunda metade da entrada, quando os blocos já estão
  /// quase no lugar: luz sobre o vazio não é reflexo de nada.
  static const double start = 0.4;

  /// A direção da faixa: rasante, de cima à esquerda para baixo à direita.
  static final Offset _direction = const Offset(1, 0.6) / math.sqrt(1.36);

  @override
  void paint(Canvas canvas, Size size) {
    final t = (progress.value - start) / (1 - start);
    if (t <= 0 || t >= 1) return;
    final strength = math.sin(t * math.pi);
    final length = size.width * _direction.dx + size.height * _direction.dy;
    final half = length * 0.22;
    final center = -half + (length + 2 * half) * t;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          _direction * (center - half),
          _direction * (center + half),
          _colors(strength),
          const [0, 0.3, 0.5, 0.7, 1],
        ),
    );
  }

  List<Color> _colors(double strength) {
    final edge = warmth.withValues(alpha: 0.06 * strength);
    final core = light.withValues(alpha: BrandColors.sheenOverText * strength);
    final clear = light.withValues(alpha: 0);
    return [clear, edge, core, edge, clear];
  }

  @override
  bool shouldRepaint(LightSweepPainter oldDelegate) =>
      oldDelegate.light != light ||
      oldDelegate.warmth != warmth ||
      oldDelegate.progress != progress;
}
