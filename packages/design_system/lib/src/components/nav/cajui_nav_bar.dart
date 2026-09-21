import 'package:design_system/src/components/nav/cajui_nav_destination.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// A barra de navegação do pé da tela: de três a cinco destinos, todos com
/// nome à vista.
///
/// Fica embaixo porque é onde o polegar alcança com o aparelho numa mão só.
/// O destino em vigor é marcado por forma (a pílula atrás do ícone) e por
/// peso do texto, e não só por cor.
class CajuiNavBar extends StatelessWidget {
  /// Cria a barra com [destinations], marcando o de índice [selectedIndex].
  const new({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(
         destinations.length >= 3 && destinations.length <= 5,
         'Com menos de três destinos não é navegação; com mais de cinco, '
         'os alvos de toque ficam pequenos demais.',
       );

  /// Os destinos, da esquerda para a direita.
  final List<CajuiNavDestination> destinations;

  /// O índice do destino em vigor.
  final int selectedIndex;

  /// Chamado com o índice do destino tocado.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.elevated,
        border: Border(top: BorderSide(color: colors.border.subtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CajuiSpacing.sm,
            vertical: CajuiSpacing.xs,
          ),
          child: Row(children: [..._items()]),
        ),
      ),
    );
  }

  Iterable<Widget> _items() sync* {
    for (final (index, destination) in destinations.indexed) {
      yield Expanded(
        child: _NavItem(
          destination: destination,
          selected: index == selectedIndex,
          onPressed: () => onSelected(index),
        ),
      );
    }
  }
}

class _NavItem extends StatelessWidget {
  const new({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final CajuiNavDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(CajuiRadius.md);
  static const _pill = BorderRadius.all(CajuiRadius.pill);

  @override
  Widget build(BuildContext context) {
    return CajuiPressable(
      onPressed: onPressed,
      toggled: selected,
      radius: _radius,
      semanticLabel: destination.label,
      builder: _surface,
    );
  }

  Widget _surface(BuildContext context, Set<WidgetState> states) {
    final theme = CajuiTheme.of(context);
    final (pill, foreground) = _paint(theme.colors, states);
    final type = selected ? theme.typography.label : theme.typography.caption;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CajuiSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: CajuiDurations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: CajuiSpacing.xl,
              vertical: CajuiSpacing.xs,
            ),
            decoration: BoxDecoration(color: pill, borderRadius: _pill),
            child: CajuiIcon(destination.icon, color: foreground),
          ),
          const SizedBox(height: CajuiSpacing.xxs),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }

  (Color, Color) _paint(CajuiColors c, Set<WidgetState> states) {
    if (selected) return (c.action.secondaryPressed, c.text.primary);
    final lifted =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);
    final pill = lifted ? c.action.secondaryHover : c.surface.elevated;
    return (pill, c.text.muted);
  }
}
