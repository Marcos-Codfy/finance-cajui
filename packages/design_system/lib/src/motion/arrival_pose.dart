import 'dart:ui' show lerpDouble;

import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_depth.dart';
import 'package:flutter/widgets.dart';

/// A conta da entrada cinematográfica: onde está, e quão nítido, um bloco
/// que chega da profundidade.
///
/// É um travelling de câmera: o bloco vem de longe e de baixo, um pouco
/// deitado e fora de foco; aproxima-se freando, passa uns 3% do lugar e
/// assenta (`CajuiCurves.settle`). A opacidade chega antes do foco — o olho
/// vê que algo está lá antes de ler o quê —, e o foco chega antes do fim do
/// movimento, para nenhum número ficar borrado mais que um instante.
abstract final class ArrivalPose {
  /// A escala de onde o bloco parte: a distância da câmera.
  static const double _farScale = 0.86;

  /// O quanto abaixo do lugar o bloco parte, em pixels lógicos.
  static const double _rise = 28;

  /// O quanto o bloco parte deitado: uns 10°.
  static const double _tilt = 0.18;

  /// A pose e o desfoque (sigma) de um bloco que já fez [progress] da sua
  /// chegada, no nível [motion].
  ///
  /// No `lite` não há desfoque; no `reduced`, só a opacidade muda — o bloco
  /// está no lugar desde o primeiro quadro.
  static (SpacePose, double) of(double progress, {required MotionLevel motion}) {
    final t = progress.clamp(0.0, 1.0);
    if (motion == MotionLevel.reduced) {
      return (SpacePose(opacity: CajuiCurves.standard.transform(t)), 0);
    }
    final travel = CajuiCurves.settle.transform(t);
    final pose = SpacePose(
      tilt: lerpDouble(_tilt, 0, travel)!,
      scale: lerpDouble(_farScale, 1, travel)!,
      shift: Offset(0, lerpDouble(_rise, 0, travel)!),
      opacity: CajuiCurves.enter.transform((t / 0.5).clamp(0.0, 1.0)),
    );
    if (!motion.allowsDecorativeMotion) return (pose, 0);
    final focus = CajuiCurves.enter.transform((t / 0.6).clamp(0.0, 1.0));
    return (pose, CajuiDepth.arrivalBlur * (1 - focus));
  }
}
