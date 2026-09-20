import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// Um chip selecionável: categoria candidata, filtro, forma de pagamento.
///
/// É o componente das três zonas de confiança (RN-744): na zona alta a
/// categoria vem num chip já selecionado; na média, em dois ou três chips
/// sem nenhum marcado.
///
/// Selecionado não é dito só pela cor: o chip ganha a marca de confirmado
/// (RNF-A11Y-03).
class CajuiChip extends StatelessWidget {
  /// Cria um chip com o rótulo [label].
  const new({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// O texto do chip.
  final String label;

  /// Se está selecionado.
  final bool selected;

  /// Chamado com o novo valor ao tocar. `null` desabilita.
  final ValueChanged<bool>? onSelected;

  static const double _height = 36;
  static const _radius = BorderRadius.all(CajuiRadius.pill);

  @override
  Widget build(BuildContext context) {
    final callback = onSelected;
    return CajuiPressable(
      onPressed: callback == null ? null : () => callback(!selected),
      toggled: selected,
      radius: _radius,
      semanticLabel: label,
      builder: _surface,
    );
  }

  Widget _surface(BuildContext context, Set<WidgetState> states) {
    final theme = CajuiTheme.of(context);
    final (background, foreground, outline) = _paint(theme.colors, states);
    return AnimatedContainer(
      duration: CajuiDurations.fast,
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: CajuiSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: _radius,
        border: Border.all(color: outline),
      ),
      child: DefaultTextStyle.merge(
        style: theme.typography.label.copyWith(color: foreground),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected) ...[
          const CajuiIcon(CajuiIconData.check, size: 16),
          const SizedBox(width: CajuiSpacing.xs),
        ],
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  /// Fundo, texto e contorno. O contorno existe para o chip em repouso ter
  /// limite visível sobre a areia: o fundo sozinho dá 1,11:1 (BL-016).
  (Color, Color, Color) _paint(CajuiColors c, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return (c.action.disabled, c.text.disabled, c.action.disabled);
    }
    if (selected) {
      return (c.action.primary, c.text.onAction, c.action.primary);
    }
    final lifted =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);
    final background = lifted ? c.action.secondaryHover : c.action.secondary;
    return (background, c.text.primary, c.border.field);
  }
}
