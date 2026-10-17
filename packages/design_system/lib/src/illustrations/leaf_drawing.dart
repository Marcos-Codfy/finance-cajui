import 'package:design_system/src/illustrations/cerrado_palette.dart';
import 'package:design_system/src/illustrations/cerrado_shapes.dart';
import 'package:flutter/widgets.dart';

/// A folha larga do cerrado: uma grande, com nervura central e laterais, e
/// uma menor por trás, mais clara, para dar profundidade sem sombra.
abstract final class LeafDrawing {
  static const _base = Offset(196, 418);
  static const _tip = Offset(360, 112);

  /// Pinta a folha em [canvas], que já está na grade de 512.
  static void paint(Canvas canvas, CerradoPalette palette) {
    final leaf = Paint()..color = palette.leaf;
    canvas
      ..drawPath(
        CerradoShapes.leaf(const Offset(206, 424), const Offset(110, 214), 64),
        Paint()..color = palette.leaf.withValues(alpha: 0.45),
      )
      ..drawLine(
        const Offset(170, 470),
        _base,
        Paint()
          ..color = palette.wood
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    final blade = CerradoShapes.leaf(_base, _tip, 118);
    canvas.drawPath(blade, leaf);
    _paintVeins(canvas, blade, palette);
  }

  /// A nervura central e três pares de laterais, presas por dentro da folha:
  /// o recorte garante que nenhuma passe da borda.
  static void _paintVeins(Canvas canvas, Path blade, CerradoPalette palette) {
    final vein = Paint()
      ..color = palette.vein
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final axis = _tip - _base;
    final normal = Offset(-axis.dy, axis.dx) / axis.distance;
    canvas
      ..save()
      ..clipPath(blade)
      ..drawLine(_base, _base + axis * 0.92, vein);
    for (final along in const [0.3, 0.48, 0.66]) {
      final from = _base + axis * along;
      final reach = 96 * (1 - along);
      final ahead = axis * 0.1;
      canvas
        ..drawLine(from, from + ahead + normal * reach, vein)
        ..drawLine(from, from + ahead - normal * reach, vein);
    }
    canvas.restore();
  }
}
