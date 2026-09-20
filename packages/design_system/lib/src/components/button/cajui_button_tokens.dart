import 'package:design_system/src/components/button/cajui_button_variant.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// Os tokens de componente do botão: que papel semântico pinta cada parte,
/// em cada variante e em cada estado.
///
/// É a terceira camada — primitivo, semântico, componente. O botão não decide
/// cor; ele pergunta aqui. E aqui ninguém escreve um hexadecimal: só aponta
/// para `action.*`, `text.*` e `intent.*`.
@immutable
class CajuiButtonTokens {
  /// As cores de um botão num dado momento.
  const new({required this.background, required this.foreground});

  /// Resolve as cores de uma variante para o conjunto de estados atual.
  factory resolve(
    CajuiColors colors,
    CajuiButtonVariant variant,
    Set<WidgetState> states,
  ) {
    if (states.contains(WidgetState.disabled)) {
      final ghost = variant == CajuiButtonVariant.ghost;
      return CajuiButtonTokens(
        background: ghost ? _transparent : colors.action.disabled,
        foreground: colors.text.disabled,
      );
    }
    return CajuiButtonTokens(
      background: _background(colors, variant, states),
      foreground: _foreground(colors, variant),
    );
  }

  /// O fundo.
  final Color background;

  /// O rótulo e o ícone.
  final Color foreground;

  static const _transparent = Color(0x00000000);

  static Color _foreground(CajuiColors c, CajuiButtonVariant variant) {
    return switch (variant) {
      CajuiButtonVariant.primary => c.text.onAction,
      CajuiButtonVariant.secondary => c.text.primary,
      CajuiButtonVariant.ghost => c.action.primary,
      CajuiButtonVariant.destructive => c.text.onAction,
    };
  }

  static Color _background(
    CajuiColors c,
    CajuiButtonVariant variant,
    Set<WidgetState> states,
  ) {
    final a = c.action;
    return switch (variant) {
      CajuiButtonVariant.primary => _pick(
        states,
        rest: a.primary,
        raised: a.primaryHover,
        pressed: a.primaryPressed,
      ),
      CajuiButtonVariant.secondary => _pick(
        states,
        rest: a.secondary,
        raised: a.secondaryHover,
        pressed: a.secondaryPressed,
      ),
      CajuiButtonVariant.ghost => _pick(
        states,
        rest: _transparent,
        raised: a.secondary,
        pressed: a.secondaryHover,
      ),
      CajuiButtonVariant.destructive => c.intent.danger,
    };
  }

  /// Pressionado vence sob o cursor e com foco, que vencem o repouso.
  static Color _pick(
    Set<WidgetState> states, {
    required Color rest,
    required Color raised,
    required Color pressed,
  }) {
    if (states.contains(WidgetState.pressed)) return pressed;
    final lifted =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);
    return lifted ? raised : rest;
  }
}
