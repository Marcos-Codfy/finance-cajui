import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:flutter/widgets.dart';

/// Os movimentos da câmera entre telas: avançar para dentro de uma tela
/// nova, recuar a de trás, e orbitar de uma aba para a outra.
///
/// O dono pediu "movimentação de câmera" junto da rolagem 3D: a troca de
/// tela deixa de ser um corte e vira um movimento de câmera. As poses saem
/// daqui, como funções puras do relógio da troca (`clock`, linear, 0 → 1), e
/// passam pela mesma lente de todo o 3D (`CajuiDepth`).
///
/// **A troca é uma passagem, e não uma mistura.** As telas do Cajui não têm
/// fundo próprio — o fundo é um só, embaixo de tudo —, e na primeira versão
/// a de trás só esmaecia até a metade: durante a troca as duas apareciam
/// juntas, uma através da outra, e o dono notou ("fica mostrando itens da
/// tela anterior com a nova tela"). Agora a de trás recua e some no
/// primeiro terço do relógio ([leaveBy]); a nova só começa a aparecer
/// quando a de trás já quase sumiu ([arriveFrom]). Em nenhum instante as
/// duas estão visíveis ao mesmo tempo.
///
/// Cada tela anda no seu trecho do relógio: a de trás recua enquanto
/// some, e a nova faz o caminho todo — de longe, deitada, até o lugar —
/// depois de começar a aparecer. Girar o que ainda não se vê seria gastar o
/// movimento.
///
/// Nos níveis de movimento: `full` gira, encolhe e apaga; `lite` tira o
/// giro e fica no deslize; `reduced` é só a passagem de opacidade.
abstract final class CameraMove {
  /// O quanto a tela nova vem deitada para trás ao chegar: uns 10°.
  static const double arrivalTilt = 0.18;

  /// O quanto a tela nova chega menor.
  static const double arrivalScale = 0.86;

  /// O quanto a tela nova sobe ao chegar, em pixels lógicos.
  static const double arrivalRise = 56;

  /// O quanto a tela de trás recua enquanto some.
  static const double recedeScale = 0.94;

  /// O giro da órbita entre abas: uns 34°.
  static const double orbitTurn = 0.6;

  /// O quanto a aba anda para o lado na órbita, em fração da largura.
  static const double orbitTravel = 0.35;

  /// Onde, no relógio da troca, a tela que sai já sumiu.
  static const double leaveBy = 0.3;

  /// Onde a tela que chega começa a aparecer: um pouco antes de a outra
  /// sumir de todo, para a passagem não piscar no fundo vazio.
  static const double arriveFrom = 0.24;

  /// Onde a tela que chega já está inteira; o resto é o assentar.
  static const double arriveBy = 0.6;

  /// A tela que chega, no relógio [clock]: de longe, deitada e menor até o
  /// lugar. [curve] é a da ida; na volta, a rota passa a de saída.
  static SpacePose arriving(
    double clock,
    MotionLevel level, {
    Curve curve = CajuiCurves.settle,
  }) {
    final away = 1 - curve.transform(arrivalClock(clock));
    final opacity = incoming(clock);
    return switch (level) {
      MotionLevel.reduced => SpacePose(opacity: opacity),
      MotionLevel.lite => SpacePose(
        shift: Offset(0, arrivalRise * away),
        opacity: opacity,
      ),
      MotionLevel.full => SpacePose(
        tilt: arrivalTilt * away,
        scale: arrivalScale + (1 - arrivalScale) * (1 - away),
        shift: Offset(0, arrivalRise * away),
        opacity: opacity,
        pivot: Alignment.bottomCenter,
      ),
    };
  }

  /// A tela de trás, no relógio [clock]: recua um pouco e some, como o
  /// fundo de uma cena quando a câmera avança.
  static SpacePose receding(
    double clock,
    MotionLevel level, {
    Curve curve = CajuiCurves.enter,
  }) {
    final opacity = outgoing(clock);
    if (level != MotionLevel.full) return SpacePose(opacity: opacity);
    final back = curve.transform(leavingClock(clock));
    return SpacePose(scale: 1 - (1 - recedeScale) * back, opacity: opacity);
  }

  /// A aba que chega na órbita, vinda do lado [direction] (1: da direita,
  /// -1: da esquerda), numa tela de largura [width].
  static SpacePose orbitIn(
    double clock,
    int direction,
    double width,
    MotionLevel level,
  ) => _orbit(
    1 - CajuiCurves.standard.transform(arrivalClock(clock)),
    direction,
    width,
    level,
    opacity: incoming(clock),
  );

  /// A aba que sai na órbita, indo para o lado oposto a [direction].
  static SpacePose orbitOut(
    double clock,
    int direction,
    double width,
    MotionLevel level,
  ) => _orbit(
    CajuiCurves.standard.transform(leavingClock(clock)),
    -direction,
    width,
    level,
    opacity: outgoing(clock),
  );

  /// A opacidade da tela que sai: inteira no começo, nenhuma em [leaveBy].
  static double outgoing(double clock) => 1 - _smooth(leavingClock(clock));

  /// A opacidade da tela que chega: nenhuma até [arriveFrom], inteira em
  /// [arriveBy].
  static double incoming(double clock) =>
      _smooth((clock - arriveFrom) / (arriveBy - arriveFrom));

  /// O trecho do relógio em que a tela que sai se move: até sumir.
  static double leavingClock(double clock) => _unit(clock / leaveBy);

  /// O trecho do relógio em que a tela que chega se move: de quando começa
  /// a aparecer até o fim.
  static double arrivalClock(double clock) =>
      _unit((clock - arriveFrom) / (1 - arriveFrom));

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

  static double _unit(double value) => value.clamp(0, 1).toDouble();

  /// Começa e termina devagar: a opacidade não dá degrau nas pontas.
  static double _smooth(double value) {
    final x = _unit(value);
    return x * x * (3 - 2 * x);
  }
}
