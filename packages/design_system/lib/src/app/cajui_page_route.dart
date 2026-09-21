import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// A troca de tela do Cajui: a tela nova sobe um pouco enquanto aparece.
///
/// Com movimento reduzido sobra só o esmaecer: a troca continua perceptível,
/// mas nada se desloca.
class CajuiPageRoute<T> extends PageRouteBuilder<T> {
  /// Cria a rota para a tela montada por [builder].
  new({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: _transition,
        transitionDuration: CajuiDurations.base,
        reverseTransitionDuration: CajuiDurations.fast,
      );

  /// Quanto a tela nova sobe, em fração da altura.
  static const double _rise = 0.04;

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: CajuiCurves.enter,
      reverseCurve: CajuiCurves.exit,
    );
    final fade = FadeTransition(opacity: eased, child: child);
    if (!CajuiTheme.of(context).motionLevel.allowsSpring) return fade;
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, _rise),
        end: Offset.zero,
      ).animate(eased),
      child: fade,
    );
  }
}
