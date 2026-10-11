import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/widgets.dart';

/// Os movimentos da câmera entre telas: avançar para dentro de uma tela
/// nova, recuar a de trás, e orbitar de uma aba para a outra.
///
/// O dono pediu "movimentação de câmera" junto da rolagem 3D: a troca de
/// tela deixa de ser um corte e vira um movimento de câmera. As poses saem
/// daqui, como funções puras do progresso `t` (0 → 1), e passam pela mesma
/// lente de todo o 3D (`CajuiDepth`). Assim a tela que chega, o carrossel e
/// a rolagem parecem filmados pela mesma câmera.
///
/// Nos níveis de movimento: `full` gira, encolhe e apaga; `lite` tira o
/// giro e fica no deslize; `reduced` é só esmaecer.
abstract final class CameraMove {
  /// O quanto a tela nova vem deitada para trás ao chegar: uns 10°.
  static const double arrivalTilt = 0.18;

  /// O quanto a tela nova chega menor.
  static const double arrivalScale = 0.86;

  /// O quanto a tela nova sobe ao chegar, em pixels lógicos.
  static const double arrivalRise = 56;

  /// O quanto a tela de trás recua enquanto a nova chega.
  static const double recedeScale = 0.94;

  /// O giro da órbita entre abas: uns 34°.
  static const double orbitTurn = 0.6;

  /// O quanto a aba anda para o lado na órbita, em fração da largura.
  static const double orbitTravel = 0.35;

  /// A tela que chega, em [t]: de longe, deitada e menor até o lugar.
  static SpacePose arriving(double t, MotionLevel level) {
    final away = 1 - t;
    return switch (level) {
      MotionLevel.reduced => SpacePose(opacity: t),
      MotionLevel.lite => SpacePose(
        shift: Offset(0, arrivalRise * away),
        opacity: _early(t),
      ),
      MotionLevel.full => SpacePose(
        tilt: arrivalTilt * away,
        scale: arrivalScale + (1 - arrivalScale) * t,
        shift: Offset(0, arrivalRise * away),
        opacity: _early(t),
        pivot: Alignment.bottomCenter,
      ),
    };
  }

  /// A tela de trás, em [t]: recua um pouco e apaga, como o fundo de uma
  /// cena quando a câmera avança.
  static SpacePose receding(double t, MotionLevel level) => switch (level) {
    MotionLevel.reduced => SpacePose.rest,
    MotionLevel.lite => SpacePose(opacity: 1 - 0.3 * t),
    MotionLevel.full => SpacePose(
      scale: 1 - (1 - recedeScale) * t,
      opacity: 1 - 0.45 * t,
    ),
  };

  /// A aba que chega na órbita, vinda do lado [direction] (1: da direita,
  /// -1: da esquerda), numa tela de largura [width].
  static SpacePose orbitIn(
    double t,
    int direction,
    double width,
    MotionLevel level,
  ) => _orbit(1 - t, direction, width, level, opacity: t);

  /// A aba que sai na órbita, indo para o lado oposto a [direction].
  static SpacePose orbitOut(
    double t,
    int direction,
    double width,
    MotionLevel level,
  ) => _orbit(t, -direction, width, level, opacity: 1 - t);

  static SpacePose _orbit(
    double away,
    int side,
    double width,
    MotionLevel level, {
    required double opacity,
  }) => switch (level) {
    MotionLevel.reduced => SpacePose(opacity: opacity),
    MotionLevel.lite => SpacePose(
      shift: Offset(side * width * orbitTravel * away, 0),
      opacity: opacity,
    ),
    MotionLevel.full => SpacePose(
      turn: side * orbitTurn * away,
      scale: 1 - 0.08 * away,
      shift: Offset(side * width * orbitTravel * away, 0),
      opacity: opacity,
    ),
  };

  /// A opacidade que chega cedo: a tela nova já está visível no primeiro
  /// terço do movimento, e o resto é só o assentar.
  static double _early(double t) => (t * 3).clamp(0, 1).toDouble();
}
