import 'package:design_system/src/motion/motion_level.dart';

/// Decide o nível de movimento em vigor.
///
/// Três vozes, nesta ordem de força: o sistema pedindo movimento reduzido
/// vence tudo (é acessibilidade, WCAG 2.3.3); depois a medição — se o aparelho
/// está perdendo quadros, o enfeite sai —; por último, a preferência de quem
/// usa. A medição só rebaixa, nunca promove: o nível não volta a subir na
/// mesma sessão, para a tela não ficar oscilando (RNF-PERF-02).
abstract final class MotionLevelResolver {
  /// O nível a usar.
  static MotionLevel resolve({
    required MotionLevel preferred,
    required bool systemReducesMotion,
    required bool framesAreDropping,
  }) {
    if (systemReducesMotion) return MotionLevel.reduced;
    if (preferred == MotionLevel.reduced) return MotionLevel.reduced;
    if (framesAreDropping) return MotionLevel.lite;
    return preferred;
  }
}
