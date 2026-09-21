import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A página de espaço, raio e sombra: as três escalas que dão forma à tela.
class LayoutPage extends StatelessWidget {
  /// Cria a página de espaço, raio e sombra.
  const new({super.key});

  static const Map<String, double> _spacing = {
    'xxs': CajuiSpacing.xxs,
    'xs': CajuiSpacing.xs,
    'sm': CajuiSpacing.sm,
    'md': CajuiSpacing.md,
    'lg': CajuiSpacing.lg,
    'xl': CajuiSpacing.xl,
    'xxl': CajuiSpacing.xxl,
    'section': CajuiSpacing.section,
    'block': CajuiSpacing.block,
    'hero': CajuiSpacing.hero,
  };

  static const Map<String, Radius> _radii = {
    'xs': CajuiRadius.xs,
    'sm': CajuiRadius.sm,
    'md': CajuiRadius.md,
    'lg': CajuiRadius.lg,
    'xl': CajuiRadius.xl,
    'pill': CajuiRadius.pill,
  };

  static final Map<String, List<BoxShadow>> _shadows = {
    'none': CajuiShadows.none,
    'contact': CajuiShadows.contact,
    'raised': CajuiShadows.raised,
    'floating': CajuiShadows.floating,
    'overlay': CajuiShadows.overlay,
  };

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Espaço, raio e sombra',
      lead:
          'Escalas curtas de propósito: com poucos degraus, duas telas '
          'feitas em dias diferentes saem com o mesmo ritmo.',
      sections: [
        _spacingSection(),
        GallerySection(
          title: 'Raio',
          child: _wrap(_radii.entries.map(_radius)),
        ),
        GallerySection(
          title: 'Sombra',
          description:
              'Só no tema claro. No escuro a profundidade vem da cor da '
              'superfície, porque sombra sobre fundo escuro não se vê.',
          child: _wrap(_shadows.entries.map(_shadow)),
        ),
      ],
    );
  }

  Widget _spacingSection() {
    return GallerySection(
      title: 'Espaçamento',
      description:
          'Em pontos lógicos. O alvo de toque mínimo é '
          '${CajuiSpacing.touchTarget.round()}, à parte da escala.',
      child: Column(
        children: [
          for (final MapEntry(:key, :value) in _spacing.entries)
            _SpacingRow(name: key, size: value),
        ],
      ),
    );
  }

  Widget _wrap(Iterable<Widget> children) => Wrap(
    spacing: CajuiSpacing.xxl,
    runSpacing: CajuiSpacing.xxl,
    children: children.toList(),
  );

  Widget _radius(MapEntry<String, Radius> entry) => _ShapeSample(
    name: entry.key,
    detail: entry.value == CajuiRadius.pill
        ? 'total'
        : '${entry.value.x.round()}',
    radius: BorderRadius.all(entry.value),
  );

  Widget _shadow(MapEntry<String, List<BoxShadow>> entry) => _ShapeSample(
    name: entry.key,
    detail: '${entry.value.length} camada(s)',
    radius: const BorderRadius.all(CajuiRadius.md),
    shadow: entry.value,
  );
}

class _SpacingRow extends StatelessWidget {
  const new({required this.name, required this.size});

  final String name;
  final double size;

  static const double _nameWidth = 96;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CajuiSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: _nameWidth,
            child: Text(
              '$name · ${size.round()}',
              style: theme.typography.label.copyWith(
                color: theme.colors.text.muted,
              ),
            ),
          ),
          Container(
            width: size,
            height: CajuiSpacing.lg,
            decoration: BoxDecoration(
              color: theme.colors.brand.accent,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeSample extends StatelessWidget {
  const new({
    required this.name,
    required this.detail,
    required this.radius,
    this.shadow = CajuiShadows.none,
  });

  final String name;
  final String detail;
  final BorderRadius radius;
  final List<BoxShadow> shadow;

  static const double _width = 120;
  static const double _height = 80;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: theme.colors.surface.elevated,
            borderRadius: radius,
            border: Border.all(color: theme.colors.border.subtle),
            boxShadow: shadow,
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Text(
          '$name · $detail',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
      ],
    );
  }
}
