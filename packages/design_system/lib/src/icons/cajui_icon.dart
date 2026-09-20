import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:flutter/widgets.dart';

/// Um ícone de traço do Cajui.
///
/// Ícone que carrega significado recebe [semanticLabel]; ícone decorativo,
/// ao lado de um texto que já diz tudo, fica sem rótulo e é escondido do
/// leitor de tela (RNF-A11Y-06).
class CajuiIcon extends StatelessWidget {
  /// Desenha [icon] com [size] pixels de lado.
  const new(
    this.icon, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  });

  /// Qual ícone.
  final CajuiIconData icon;

  /// O lado do ícone. A área tocável é responsabilidade de quem o envolve.
  final double size;

  /// A cor do traço. Sem ela, herda a do texto em volta.
  final Color? color;

  /// O significado do ícone, quando ele tem um.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final stroke = color ?? DefaultTextStyle.of(context).style.color;
    final label = semanticLabel;
    return Semantics(
      label: label,
      image: label != null,
      excludeSemantics: label == null,
      child: CustomPaint(
        size: Size.square(size),
        painter: _IconPainter(icon, stroke ?? const Color(0xFF000000)),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  const new(this.icon, this.color);

  final CajuiIconData icon;
  final Color color;

  /// O traço da marca: 1,75 px na grade de 24, com pontas e junções redondas.
  static const double _strokeOn24 = 1.75;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    final path = Path();
    icon.build(path);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeOn24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas
      ..scale(scale)
      ..drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) =>
      icon != oldDelegate.icon || color != oldDelegate.color;
}
