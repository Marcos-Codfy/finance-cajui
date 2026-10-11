import 'dart:math' as math;

import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_depth.dart';
import 'package:flutter/widgets.dart';

/// A conta da rolagem em profundidade: a pose de um item conforme o quanto
/// dele está à vista.
///
/// A tela se comporta como a face de um tambor: plana no meio, curvando para
/// longe nas bordas. Um item **inteiro à vista fica plano** — é ali que se
/// lê, e nada pode tremer embaixo do olho. Só o que está cortado pela borda
/// curva: o que entra por baixo vem deitado e menor, e assenta conforme sobe;
/// o que sai por cima recua, encolhe e é coberto pelo seguinte.
///
/// Item mais alto que a faixa da borda só curva quando sobra dele menos que
/// a faixa: um bloco comprido continua plano enquanto está sendo lido.
abstract final class DrumPose {
  /// Quanto o item que entra fica para trás, como fração da faixa: é a
  /// paralaxe — ele sobe mais devagar que a lista e "chega" depois.
  static const double _enterLag = 0.2;

  /// Quanto o item que sai fica para trás: mais que na entrada, para o
  /// seguinte passar por cima dele.
  static const double _leaveLag = 0.35;

  /// A pose do item que vai de [top] a [bottom], medidos a partir do alto
  /// de uma tela de altura [extent]. Com [fades], ele também esmaece na
  /// borda — só no nível `full`, porque esmaecer custa uma camada a mais.
  static SpacePose of({
    required double top,
    required double bottom,
    required double extent,
    bool fades = true,
  }) {
    final height = bottom - top;
    if (height <= 0 || extent <= 0) return SpacePose.rest;
    final span = math.min(height, extent * CajuiDepth.edgeZone);
    final entering = ((top - (extent - span)) / span).clamp(0.0, 1.0);
    if (entering > 0) return _entering(_ease(entering), span, fades: fades);
    final leaving = ((span - bottom) / span).clamp(0.0, 1.0);
    if (leaving > 0) return _leaving(_ease(leaving), span, fades: fades);
    return SpacePose.rest;
  }

  /// Perto do plano a curva é suave: o primeiro pixel cortado não pode já
  /// sair girando.
  static double _ease(double progress) =>
      CajuiCurves.standard.transform(progress);

  /// Deitado para trás, preso pela borda de cima, que é a que já se vê.
  static SpacePose _entering(
    double amount,
    double span, {
    required bool fades,
  }) {
    return SpacePose(
      tilt: CajuiDepth.drumTilt * amount,
      scale: 1 - 0.1 * amount,
      shift: Offset(0, span * _enterLag * amount),
      opacity: fades ? 1 - 0.6 * amount : 1,
      pivot: Alignment.topCenter,
    );
  }

  /// Recuando, preso pela borda de baixo: o alto vai para longe primeiro.
  static SpacePose _leaving(double amount, double span, {required bool fades}) {
    return SpacePose(
      tilt: -CajuiDepth.drumTilt * 0.8 * amount,
      scale: 1 - 0.12 * amount,
      shift: Offset(0, span * _leaveLag * amount),
      opacity: fades ? 1 - 0.7 * amount : 1,
      pivot: Alignment.bottomCenter,
    );
  }
}
