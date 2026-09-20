import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_scope.dart';
import 'package:gallery/src/pages/tokens/color_roles.dart';
import 'package:gallery/src/pages/tokens/color_swatch_tile.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A página de cores: todo papel semântico, no tema em vigor.
class ColorsPage extends StatelessWidget {
  /// Cria a página de cores.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return GalleryPage(
      title: 'Cores',
      lead:
          'O app nunca pede um tom; pede um papel. Os valores abaixo são os '
          'do tema em vigor — troque o tema na barra para ver o outro.',
      sections: [
        for (final group in ColorRoles.groupsOf(colors))
          GallerySection(
            title: group.title,
            description: group.note,
            child: _swatches(group.roles),
          ),
        const _ShortfallChoice(),
      ],
    );
  }

  Widget _swatches(Map<String, Color> roles) {
    return Wrap(
      spacing: CajuiSpacing.lg,
      runSpacing: CajuiSpacing.xl,
      children: [
        for (final MapEntry(key: name, value: color) in roles.entries)
          ColorSwatchTile(name: name, color: color),
      ],
    );
  }
}

/// Troca a versão da falta do mês para a gallery inteira.
class _ShortfallChoice extends StatelessWidget {
  const new();

  static const Map<ShortfallStyle, String> _labels = {
    ShortfallStyle.calm: 'Barro, com ênfase na ação',
    ShortfallStyle.alarm: 'Vermelho, padrão de mercado',
  };

  @override
  Widget build(BuildContext context) {
    final controller = GalleryScope.of(context);
    return GallerySection(
      title: 'Versão em vigor da falta do mês',
      description:
          'Vale para todas as páginas. A comparação lado a lado fica em '
          'Telas.',
      child: Wrap(
        spacing: CajuiSpacing.sm,
        runSpacing: CajuiSpacing.sm,
        children: [
          for (final MapEntry(key: style, value: label) in _labels.entries)
            CajuiChip(
              label: label,
              selected: controller.shortfallStyle == style,
              onSelected: (_) => controller.useShortfallStyle(style),
            ),
        ],
      ),
    );
  }
}
