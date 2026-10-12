import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/interaction/cajui_touch.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Uma lista de opções de escolha única, para dentro de folha ou diálogo.
///
/// A opção escolhida leva a marca de confirmado, além da cor. Cada linha é um
/// controle próprio, alcançável por teclado, e diz ao leitor de tela se está
/// selecionada.
class CajuiOptionList<T> extends StatelessWidget {
  /// Cria a lista. [labelOf] diz como escrever cada opção.
  const new({
    required this.options,
    required this.labelOf,
    required this.onSelected,
    this.selected,
    super.key,
  });

  /// As opções, na ordem em que aparecem.
  final List<T> options;

  /// O texto de uma opção.
  final String Function(T option) labelOf;

  /// Chamado com a opção tocada.
  final ValueChanged<T> onSelected;

  /// A opção escolhida, se houver.
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final option in options) _row(context, option)],
    );
  }

  Widget _row(BuildContext context, T option) {
    final isSelected = option == selected;
    return CajuiPressable(
      onPressed: () => onSelected(option),
      touch: CajuiTouch.card,
      // Escolhido entre os irmãos, e não "ligado": o leitor de tela anuncia
      // um item de lista selecionado, não uma chave.
      selected: isSelected,
      radius: const BorderRadius.all(CajuiRadius.md),
      semanticLabel: labelOf(option),
      builder: (context, states) => _surface(
        context,
        option,
        selected: isSelected,
        lifted: states.contains(WidgetState.hovered),
      ),
    );
  }

  Widget _surface(
    BuildContext context,
    T option, {
    required bool selected,
    required bool lifted,
  }) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: lifted || selected ? colors.surface.sunken : null,
        borderRadius: const BorderRadius.all(CajuiRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CajuiSpacing.lg,
          vertical: CajuiSpacing.md + CajuiSpacing.xxs,
        ),
        child: Row(
          children: [
            Expanded(child: _label(theme, option, selected: selected)),
            if (selected)
              CajuiIcon(CajuiIconData.check, color: colors.action.primary),
          ],
        ),
      ),
    );
  }

  /// O selecionado ganha peso, além do ícone: dois sinais, nenhum deles cor.
  Widget _label(CajuiThemeData theme, T option, {required bool selected}) {
    return Text(
      labelOf(option),
      style: theme.typography.body.copyWith(
        color: theme.colors.text.primary,
        fontVariations: [FontVariation('wght', selected ? 600 : 400)],
      ),
    );
  }
}
