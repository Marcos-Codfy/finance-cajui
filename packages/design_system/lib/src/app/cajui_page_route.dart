import 'package:design_system/src/motion/cajui_posed.dart';
import 'package:design_system/src/motion/camera_move.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// A troca de tela do Cajui como movimento de câmera (`CameraMove`): a
/// câmera avança, a tela nova chega de longe — deitada, menor — e assenta;
/// a de trás recua e apaga, como o fundo de uma cena. Voltar é o mesmo
/// movimento ao contrário: a câmera recua.
///
/// Com movimento reduzido sobra só o esmaecer: a troca continua perceptível,
/// mas nada se desloca.
class CajuiPageRoute<T> extends PageRouteBuilder<T> {
  /// Cria a rota para a tela montada por [builder].
  new({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: _transition,
        transitionDuration: CajuiDurations.slow,
        reverseTransitionDuration: CajuiDurations.base,
      );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final level = motionOf(context);
    final arriving = CurvedAnimation(
      parent: animation,
      curve: CajuiCurves.settle,
      reverseCurve: CajuiCurves.exit,
    );
    final receding = CurvedAnimation(
      parent: secondaryAnimation,
      curve: CajuiCurves.enter,
      reverseCurve: CajuiCurves.exit,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([arriving, receding]),
      child: child,
      builder: (context, child) => CajuiPosed(
        pose: CameraMove.receding(receding.value, level),
        child: CajuiPosed(
          pose: CameraMove.arriving(_progress(arriving.value, level), level),
          child: child!,
        ),
      ),
    );
  }

  /// A curva com mola passa um pouco do fim e volta: no giro e na escala,
  /// é o assentar; no esmaecer do movimento reduzido, ficaria só o número
  /// errado — ali o progresso é o de verdade, sem passar de 1.
  static double _progress(double value, MotionLevel level) =>
      level == MotionLevel.reduced ? value.clamp(0, 1).toDouble() : value;
}
