import 'dart:math' as math;

import 'package:design_system/src/illustrations/cajui_cerrado.dart';
import 'package:design_system/src/illustrations/cashew_drawing.dart';
import 'package:design_system/src/illustrations/cerrado_palette.dart';
import 'package:design_system/src/illustrations/ipe_drawing.dart';
import 'package:design_system/src/illustrations/leaf_drawing.dart';
import 'package:flutter/widgets.dart';

/// Pinta uma ilustração do Cerrado: o disco do fundo e o desenho por cima,
/// balançando de [sway] em volta do pé.
///
/// Tudo é desenhado numa grade de 512, a mesma do símbolo da marca, e
/// escalado para o tamanho pedido: vetor, sem peso no pacote do app.
class CerradoPainter extends CustomPainter {
  /// Cria o pintor de [kind] com as cores de [palette].
  const new({required this.kind, required this.palette, this.sway = 0});

  /// Qual ilustração.
  final CajuiCerrado kind;

  /// As cores, já tiradas do tema.
  final CerradoPalette palette;

  /// O balanço, de -1 a 1; 0 é o desenho parado, de pé.
  final double sway;

  static const _grid = 512.0;

  /// O pé do desenho: o balanço gira em volta dele, como planta ao vento.
  static const _root = Offset(256, 470);

  /// O giro máximo do balanço: pouco, para ser ambiente e não chamar o olho.
  static const double _maxTilt = 3 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.shortestSide / _grid)
      ..drawCircle(
        const Offset(256, 276),
        200,
        Paint()..color = palette.backdrop,
      )
      ..translate(_root.dx, _root.dy)
      ..rotate(sway * _maxTilt)
      ..translate(-_root.dx, -_root.dy);
    final draw = switch (kind) {
      CajuiCerrado.cashew => CashewDrawing.paint,
      CajuiCerrado.leaf => LeafDrawing.paint,
      CajuiCerrado.ipe => IpeDrawing.paint,
    };
    draw(canvas, palette);
  }

  @override
  bool shouldRepaint(CerradoPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      sway != oldDelegate.sway ||
      palette != oldDelegate.palette;
}
