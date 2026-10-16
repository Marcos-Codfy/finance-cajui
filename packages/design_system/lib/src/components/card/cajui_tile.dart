import 'package:design_system/src/components/card/cajui_card.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// Uma porta de destaque: ícone, nome e uma frase do que tem lá dentro.
///
/// Nasceu para o Início (16/10/2026): as quatro portas mais usadas em grade
/// cabem numa olhada, onde oito linhas pediam rolagem até "Cartões".
class CajuiTile extends StatelessWidget {
  /// Cria a porta [title], com [subtitle] e o ícone [icon].
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  /// O ícone da porta.
  final CajuiIconData icon;

  /// O nome: "Cartões".
  final String title;

  /// O que tem lá dentro, em uma ou duas linhas.
  final String subtitle;

  /// Abre a porta.
  final VoidCallback onPressed;

  static const double _iconBox = 40;

  Widget _badge(CajuiColors colors) => SizedBox.square(
    dimension: _iconBox,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.sunken,
        borderRadius: const BorderRadius.all(CajuiRadius.sm),
      ),
      child: Center(child: CajuiIcon(icon)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return CajuiCard(
      onPressed: onPressed,
      semanticLabel: title,
      padding: const EdgeInsets.all(CajuiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge(colors),
          const SizedBox(height: CajuiSpacing.md),
          Text(
            title,
            style: theme.typography.body.copyWith(
              color: colors.text.primary,
              fontVariations: const [FontVariation('wght', 600)],
            ),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption.copyWith(color: colors.text.faint),
          ),
        ],
      ),
    );
  }
}
