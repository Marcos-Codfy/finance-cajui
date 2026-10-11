import 'dart:math' as math;

import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_depth.dart';
import 'package:flutter/widgets.dart';

/// A conta do carrossel 3D: a pose de uma página conforme a distância dela
/// até o centro do palco.
///
/// É o mesmo tambor da rolagem em profundidade, deitado: a página do centro
/// fica de frente; as vizinhas giram com a borda de fora indo para longe,
/// encolhem e esmaecem. Da segunda vizinha em diante, elas se escondem atrás
/// da primeira — o palco mostra três páginas, nunca uma fila.
abstract final class CarouselPose {
  /// O quanto as páginas além da vizinha se aproximam umas das outras: elas
  /// se empilham atrás da vizinha em vez de seguir a fila.
  static const double _farSpacing = 0.55;

  /// A pose da página a [distance] páginas do centro (negativo: à esquerda),
  /// com [spacing] pixels entre o centro de uma página e o da seguinte.
  ///
  /// Com [flat] — o movimento reduzido — a página só anda de lado: nada
  /// gira, nada encolhe, nada some.
  static SpacePose of(
    double distance, {
    required double spacing,
    bool flat = false,
  }) {
    if (flat) return SpacePose(shift: Offset(distance * spacing, 0));
    final reach = distance.abs();
    final side = distance.sign;
    final near = math.min<double>(reach, 1);
    final far = math.max<double>(reach - 1, 0);
    return SpacePose(
      turn: side * near * CajuiDepth.carouselTurn,
      scale: 1 - 0.12 * near - 0.08 * math.min(far, 1.0),
      shift: Offset(side * (near + far * _farSpacing) * spacing, 0),
      opacity: (1 - 0.3 * near - 0.7 * far).clamp(0.0, 1.0),
    );
  }
}
