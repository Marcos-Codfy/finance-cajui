import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// Desenha o anel de foco do teclado em volta de [child], afastado dele.
///
/// Entre o controle e o anel fica uma folga na cor da superfície. Sem ela, o
/// anel "céu" encostaria no botão "cajuí forte" com 1,01:1 de contraste e
/// desapareceria (BL-016). Com ela, folga × botão dá 5,22:1 e anel × folga,
/// 5,15:1 — os dois conferidos pelo teste de contraste.
///
/// O anel é pintado por cima, fora dos limites do filho: aparecer ou sumir não
/// muda o layout de nada em volta.
class FocusRing extends StatelessWidget {
  /// Envolve [child] com um anel visível quando [visible] é verdadeiro.
  const new({
    required this.visible,
    required this.radius,
    required this.child,
    super.key,
  });

  /// Largura da folga e do anel, em pixels lógicos. Dois de cada: o mínimo
  /// que a WCAG 2.4.11 considera visível.
  static const double strokeWidth = 2;

  /// Se o anel aparece. Só foco de teclado mostra anel; toque e clique, não.
  final bool visible;

  /// O raio de canto do controle, que o anel acompanha.
  final BorderRadius radius;

  /// O controle.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = CajuiTheme.of(context).colors.border;
    return CustomPaint(
      foregroundPainter: visible
          ? _FocusRingPainter(
              ring: border.focusRing,
              gap: border.focusGap,
              radius: radius,
            )
          : null,
      child: child,
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const new({required this.ring, required this.gap, required this.radius});

  final Color ring;
  final Color gap;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = radius.toRRect(Offset.zero & size);
    const width = FocusRing.strokeWidth;
    _stroke(canvas, shape.inflate(width / 2), gap);
    _stroke(canvas, shape.inflate(width * 1.5), ring);
  }

  void _stroke(Canvas canvas, RRect shape, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = FocusRing.strokeWidth
      ..color = color;
    canvas.drawRRect(shape, paint);
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      ring != oldDelegate.ring ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius;
}
