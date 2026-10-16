import 'package:design_system/src/components/credit_card/cajui_card_skin.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// Os tons do cerrado em bolinhas, para escolher a cor do cartão vendo a
/// cor — e não lendo o nome dela numa lista, como era (16/10/2026).
///
/// Cada bolinha tem o gradiente do tom; a escolhida ganha o anel e o visto.
/// O leitor de tela ouve o nome do tom e se está escolhido.
class CajuiCardSkinPicker extends StatelessWidget {
  /// Cria o seletor com [selected] escolhido.
  const new({required this.selected, required this.onChanged, super.key});

  /// O tom escolhido.
  final CajuiCardSkin selected;

  /// Avisa o tom tocado.
  final ValueChanged<CajuiCardSkin> onChanged;

  /// O diâmetro da bolinha; o toque vale um pouco além, pelo espaçamento.
  static const double size = 44;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: CajuiSpacing.md,
    runSpacing: CajuiSpacing.md,
    children: [for (final skin in CajuiCardSkin.values) _swatch(context, skin)],
  );

  Widget _swatch(BuildContext context, CajuiCardSkin skin) {
    final colors = CajuiTheme.of(context).colors;
    final chosen = skin == selected;
    final ink = skin == CajuiCardSkin.cajui
        ? colors.text.onAction
        : CajuiCardSkin.ink;
    return CajuiPressable(
      onPressed: () => onChanged(skin),
      semanticLabel: skin.label,
      selected: chosen,
      radius: const BorderRadius.all(Radius.circular(size)),
      builder: (context, _) => Container(
        width: size,
        height: size,
        decoration: _disc(colors, skin, chosen: chosen),
        child: chosen
            ? Center(child: CajuiIcon(CajuiIconData.check, color: ink))
            : null,
      ),
    );
  }

  /// A bolinha: o gradiente do tom, com o anel quando escolhida.
  static BoxDecoration _disc(
    CajuiColors colors,
    CajuiCardSkin skin, {
    required bool chosen,
  }) => BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        skin.top ?? colors.action.primary,
        skin.bottom ?? colors.action.primaryPressed,
      ],
    ),
    border: Border.all(
      color: chosen ? colors.border.focusRing : colors.border.subtle,
      width: chosen ? 3 : 1,
    ),
  );
}
