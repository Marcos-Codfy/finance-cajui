import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores de ação: `action.primary`, `action.primaryHover`…
///
/// **É aqui que se muda a cor de todos os botões de ação do app.** Botão, chip
/// selecionado, chave ligada e link de destaque leem daqui; nenhum deles
/// conhece o laranja-cajuí pelo nome.
@immutable
class ActionColors {
  /// Cria o conjunto de cores de ação de um tema.
  const new({
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.secondary,
    required this.secondaryHover,
    required this.secondaryPressed,
    required this.disabled,
  });

  /// Fundo do botão primário em repouso.
  final Color primary;

  /// Fundo do botão primário sob o cursor ou com foco.
  final Color primaryHover;

  /// Fundo do botão primário pressionado.
  final Color primaryPressed;

  /// Fundo do botão secundário em repouso.
  final Color secondary;

  /// Fundo do botão secundário sob o cursor.
  final Color secondaryHover;

  /// Fundo do botão secundário pressionado.
  final Color secondaryPressed;

  /// Fundo de qualquer controle desabilitado.
  final Color disabled;

  /// Ações do tema claro. O cajuí puro não entra: branco sobre ele dá 3,68:1.
  static const light = ActionColors(
    primary: CajuiPalette.cajuiStrong,
    primaryHover: CajuiPalette.cajuiStrongHover,
    primaryPressed: CajuiPalette.cajuiDeep,
    secondary: CajuiPalette.sandDeep,
    secondaryHover: CajuiPalette.sandMuted,
    secondaryPressed: CajuiPalette.sandMuted,
    disabled: CajuiPalette.sandMuted,
  );

  /// Ações do tema escuro.
  static const dark = ActionColors(
    primary: CajuiPalette.cajuiLight,
    primaryHover: CajuiPalette.cajuiLightHover,
    primaryPressed: CajuiPalette.cajuiLightPressed,
    secondary: CajuiPalette.nightHigh,
    secondaryHover: CajuiPalette.nightRaised,
    secondaryPressed: CajuiPalette.nightDeep,
    disabled: CajuiPalette.nightHigh,
  );
}
