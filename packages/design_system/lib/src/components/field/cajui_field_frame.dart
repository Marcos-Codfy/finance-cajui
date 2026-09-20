import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// A moldura de todo campo: rótulo em cima, caixa no meio, apoio ou erro
/// embaixo.
///
/// Três decisões de acessibilidade moram aqui, para nenhum campo esquecer:
/// o rótulo fica **sempre visível** (texto de exemplo que some ao digitar não
/// é rótulo); a caixa tem contorno próprio, porque a areia funda sozinha dá
/// 1,11:1 contra a areia (BL-016); e o erro é **texto persistente** junto ao
/// campo, com ícone — nunca só cor, nunca aviso que some (RNF-A11Y-13).
class CajuiFieldFrame extends StatelessWidget {
  /// Monta a moldura em volta de [child].
  const new({
    required this.label,
    required this.child,
    this.helper,
    this.error,
    this.focused = false,
    this.hovered = false,
    this.enabled = true,
    super.key,
  });

  /// O nome do campo.
  final String label;

  /// O conteúdo da caixa.
  final Widget child;

  /// Texto de apoio. Some quando há [error].
  final String? helper;

  /// A mensagem de erro, no guia de voz: o que houve e o que fazer.
  final String? error;

  /// Se o campo está com o foco.
  final bool focused;

  /// Se o cursor está sobre o campo.
  final bool hovered;

  /// Se o campo aceita entrada.
  final bool enabled;

  static const double _minHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final labelColor = enabled
        ? theme.colors.text.muted
        : theme.colors.text.disabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.typography.label.copyWith(color: labelColor),
          ),
        ),
        const SizedBox(height: CajuiSpacing.xs + CajuiSpacing.xxs),
        _box(theme.colors),
        _support(context),
      ],
    );
  }

  Widget _box(CajuiColors colors) {
    final (outline, width) = _outline(colors);
    return AnimatedContainer(
      duration: CajuiDurations.fast,
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsets.symmetric(horizontal: CajuiSpacing.lg),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: enabled ? colors.surface.sunken : colors.action.disabled,
        borderRadius: const BorderRadius.all(CajuiRadius.md),
        border: Border.all(color: outline, width: width),
      ),
      child: child,
    );
  }

  /// Erro e foco engrossam o contorno: a diferença é de forma, além de cor.
  (Color, double) _outline(CajuiColors colors) {
    if (!enabled) return (colors.action.disabled, 1.5);
    if (error != null) return (colors.intent.notice, 2);
    if (focused) return (colors.border.strong, 2);
    return (hovered ? colors.text.muted : colors.border.field, 1.5);
  }

  Widget _support(BuildContext context) {
    final message = error ?? helper;
    if (message == null) return const SizedBox.shrink();
    final theme = CajuiTheme.of(context);
    final isError = error != null;
    final color = isError
        ? theme.colors.intent.notice
        : theme.colors.text.faint;
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.xs + CajuiSpacing.xxs),
      child: Semantics(
        liveRegion: isError,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError) ...[
              CajuiIcon(CajuiIconData.info, size: 16, color: color),
              const SizedBox(width: CajuiSpacing.xs),
            ],
            Expanded(
              child: Text(
                message,
                style: theme.typography.caption.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
