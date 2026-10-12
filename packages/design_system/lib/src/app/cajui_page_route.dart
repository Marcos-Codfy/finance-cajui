import 'package:design_system/src/motion/cajui_posed.dart';
import 'package:design_system/src/motion/camera_move.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// A troca de tela do Cajui como movimento de câmera (`CameraMove`): a
/// câmera avança, a tela nova chega de longe — deitada, menor — e assenta;
/// a de trás recua e apaga, como o fundo de uma cena. Voltar é o mesmo
/// movimento ao contrário: a câmera recua.
///
/// As duas telas nunca aparecem juntas: a de trás some antes de a nova
/// aparecer (ver `CameraMove`). Com movimento reduzido sobra só essa
/// passagem de opacidade: a troca continua perceptível, mas nada se desloca.
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
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) => CajuiPosed(
        pose: CameraMove.receding(
          secondaryAnimation.value,
          level,
          curve: _curve(secondaryAnimation, CajuiCurves.enter),
        ),
        child: CajuiPosed(
          pose: CameraMove.arriving(
            animation.value,
            level,
            curve: _curve(animation, CajuiCurves.settle),
          ),
          child: child!,
        ),
      ),
    );
  }

  /// A curva da ida, ou a de saída na volta. A câmera recebe o relógio
  /// linear, e não a animação já curvada: a passagem de uma tela para a
  /// outra precisa das duas no mesmo relógio, ou uma curva adiantaria a
  /// tela nova sobre a velha que ainda não sumiu.
  static Curve _curve(Animation<double> animation, Curve forward) =>
      animation.status == AnimationStatus.reverse ? CajuiCurves.exit : forward;
}
