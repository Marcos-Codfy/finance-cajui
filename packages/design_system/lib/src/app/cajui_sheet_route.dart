import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// O painel que sobe de baixo, por cima da tela, para as escolhas curtas —
/// categoria, forma de pagamento, dia (17/10/2026). A tela de trás continua
/// à vista e escurecida: o valor digitado não some, e tocar fora fecha.
///
/// Com movimento reduzido, o painel aparece sem subir.
class CajuiSheetRoute<T> extends PopupRoute<T> {
  /// Cria o painel com o conteúdo de [builder].
  new({required this.builder, super.settings});

  /// O conteúdo, em geral um `CajuiSheet`.
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Fechar';

  @override
  Duration get transitionDuration => CajuiDurations.base;

  @override
  Duration get reverseTransitionDuration => CajuiDurations.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildModalBarrier() => Builder(
    builder: (context) => FadeTransition(
      opacity: animation!,
      child: ModalBarrier(
        color: CajuiTheme.of(context).colors.surface.scrim,
        semanticsLabel: barrierLabel,
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (motionOf(context) == MotionLevel.reduced) {
      return FadeTransition(opacity: animation, child: child);
    }
    final rise = CurvedAnimation(
      parent: animation,
      curve: CajuiCurves.enter,
      reverseCurve: CajuiCurves.exit,
    );
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(rise),
      child: child,
    );
  }
}
