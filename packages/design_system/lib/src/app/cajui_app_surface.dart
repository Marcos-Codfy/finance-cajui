import 'package:design_system/src/feedback/cajui_feedback.dart';
import 'package:design_system/src/feedback/cajui_feedback_scope.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_level_resolver.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// O chão de um app do Cajui: entrega o tema e o retorno sensorial a tudo o
/// que está abaixo, pinta o fundo e define o texto padrão.
///
/// Existe para o app não repetir esta montagem — e, sobretudo, para não
/// precisar escolher cor de fundo nem estilo de texto por conta própria.
class CajuiAppSurface extends StatelessWidget {
  /// Monta o chão com o tema [theme] e o retorno [feedback].
  const new({
    required this.theme,
    required this.feedback,
    required this.child,
    super.key,
  });

  /// O tema em vigor.
  final CajuiThemeData theme;

  /// Por onde saem som e vibração.
  final CajuiFeedback feedback;

  /// O app.
  final Widget child;

  /// O tema em vigor, com menos movimento quando a pessoa pediu isso nas
  /// configurações do aparelho.
  ///
  /// [dark] é a escolha de quem usa: `true` força o escuro, `false` o claro.
  /// Sem escolha, segue o aparelho — é o padrão de quem incorpora a superfície
  /// sem oferecer o ajuste.
  ///
  /// [framesAreDropping] vem de quem mede os quadros no aparelho: quando ele
  /// não dá conta, o movimento baixa um nível em vez de travar.
  static CajuiThemeData themeOf(
    BuildContext context, {
    bool? dark,
    bool framesAreDropping = false,
  }) {
    final isDark =
        dark ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final theme = isDark ? CajuiThemeData.dark() : CajuiThemeData.light();
    return theme.withMotionLevel(
      MotionLevelResolver.resolve(
        preferred: MotionLevel.full,
        systemReducesMotion: MediaQuery.disableAnimationsOf(context),
        framesAreDropping: framesAreDropping,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CajuiTheme(
      data: theme,
      child: CajuiFeedbackScope(
        feedback: feedback,
        child: AnimatedContainer(
          duration: CajuiDurations.base,
          color: theme.colors.surface.base,
          child: DefaultTextStyle(
            style: theme.typography.body.copyWith(
              color: theme.colors.text.primary,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
