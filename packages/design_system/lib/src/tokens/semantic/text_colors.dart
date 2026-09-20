import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores de texto: `text.primary`, `text.muted`, `text.faint`…
///
/// Cada par texto × superfície usado junto passa no teste automatizado de
/// contraste (RNF-A11Y-02). `disabled` é a única exceção, porque a WCAG isenta
/// controle desabilitado.
@immutable
class TextColors {
  /// Cria o conjunto de cores de texto de um tema.
  const new({
    required this.primary,
    required this.muted,
    required this.faint,
    required this.onAction,
    required this.link,
    required this.disabled,
  });

  /// Texto principal e números.
  final Color primary;

  /// Texto secundário.
  final Color muted;

  /// Legenda, rótulo, texto de apoio dentro de campo.
  final Color faint;

  /// Texto sobre o botão primário.
  final Color onAction;

  /// Link e ação textual.
  final Color link;

  /// Texto de controle desabilitado.
  final Color disabled;

  /// Texto do tema claro.
  static const light = TextColors(
    primary: CajuiPalette.ink,
    muted: CajuiPalette.inkSoft,
    faint: CajuiPalette.inkFaint,
    onAction: CajuiPalette.paper,
    link: CajuiPalette.sky,
    disabled: CajuiPalette.inkDisabled,
  );

  /// Texto do tema escuro.
  static const dark = TextColors(
    primary: CajuiPalette.moon,
    muted: CajuiPalette.moonSoft,
    faint: CajuiPalette.moonFaint,
    onAction: CajuiPalette.night,
    link: CajuiPalette.skyLight,
    disabled: CajuiPalette.moonDisabled,
  );
}
