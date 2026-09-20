import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_group.dart';

/// O menu lateral da gallery: os grupos e, dentro de cada um, as páginas.
class GalleryNav extends StatelessWidget {
  /// Cria o menu com a página [selected] marcada.
  const new({required this.selected, required this.onSelect, super.key});

  /// A página aberta.
  final GalleryDestination selected;

  /// Chamado quando outra página é escolhida.
  final ValueChanged<GalleryDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(CajuiSpacing.lg),
      children: [
        for (final group in GalleryGroup.values)
          if (GalleryDestination.inGroup(group).isNotEmpty) ..._group(group),
      ],
    );
  }

  List<Widget> _group(GalleryGroup group) => [
    _GroupTitle(group.title),
    for (final destination in GalleryDestination.inGroup(group))
      _NavItem(
        destination: destination,
        selected: destination == selected,
        onPressed: () => onSelect(destination),
      ),
    const SizedBox(height: CajuiSpacing.lg),
  ];
}

class _GroupTitle extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CajuiSpacing.md,
        CajuiSpacing.sm,
        CajuiSpacing.md,
        CajuiSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.typography.overline.copyWith(
          color: theme.colors.text.faint,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const new({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final GalleryDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(CajuiRadius.sm);

  @override
  Widget build(BuildContext context) {
    // Item de menu não é chave: o som é o de toque, e o leitor de tela ouve
    // "selecionado", não "ligado".
    return Semantics(
      selected: selected,
      child: CajuiPressable(
        onPressed: onPressed,
        radius: _radius,
        semanticLabel: destination.title,
        builder: _label,
      ),
    );
  }

  Widget _label(BuildContext context, Set<WidgetState> states) {
    final theme = CajuiTheme.of(context);
    final lit = selected || states.contains(WidgetState.hovered);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: lit ? theme.colors.surface.sunken : null,
        borderRadius: _radius,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: CajuiSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: CajuiSpacing.md),
        alignment: Alignment.centerLeft,
        child: Text(
          destination.title,
          style: theme.typography.label.copyWith(
            color: selected
                ? theme.colors.text.primary
                : theme.colors.text.muted,
          ),
        ),
      ),
    );
  }
}
