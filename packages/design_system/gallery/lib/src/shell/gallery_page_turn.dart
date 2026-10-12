import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_pager.dart';

/// O fim de cada página: a anterior à esquerda e a próxima à direita.
///
/// Quem lê até o fim segue lendo, sem voltar ao menu. A ordem é a do menu,
/// tirada do próprio enum: página nova entra no lugar certo sozinha.
class GalleryPageTurn extends StatelessWidget {
  /// Cria o rodapé com a anterior e a próxima de [pager].
  const new({required this.pager, super.key});

  /// A página aberta e o jeito de ir a outra.
  final GalleryPager pager;

  @override
  Widget build(BuildContext context) {
    final border = CajuiTheme.of(context).colors.border.subtle;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: CajuiSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CajuiSpacing.lg,
          children: [
            Expanded(child: _side(pager.previous)),
            Expanded(child: _side(pager.next, forward: true)),
          ],
        ),
      ),
    );
  }

  Widget _side(GalleryDestination? destination, {bool forward = false}) =>
      destination == null
      ? const SizedBox.shrink()
      : _Turn(
          destination: destination,
          onSelect: pager.onOpen,
          forward: forward,
        );
}

class _Turn extends StatelessWidget {
  const new({
    required this.destination,
    required this.onSelect,
    this.forward = false,
  });

  final GalleryDestination destination;
  final ValueChanged<GalleryDestination> onSelect;
  final bool forward;

  static const _radius = BorderRadius.all(CajuiRadius.md);

  @override
  Widget build(BuildContext context) {
    final where = forward ? 'Próxima' : 'Anterior';
    return CajuiPressable(
      onPressed: () => onSelect(destination),
      radius: _radius,
      semanticLabel: forward
          ? 'Próxima página: ${destination.title}'
          : 'Página anterior: ${destination.title}',
      builder: (context, states) => _face(context, states, where),
    );
  }

  Widget _face(BuildContext context, Set<WidgetState> states, String where) {
    final theme = CajuiTheme.of(context);
    final hovered = states.contains(WidgetState.hovered);
    final icon = CajuiIcon(
      forward ? CajuiIconData.chevronRight : CajuiIconData.chevronLeft,
      color: theme.colors.text.muted,
    );
    final words = _words(theme, where);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hovered ? theme.colors.surface.sunken : null,
        borderRadius: _radius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(CajuiSpacing.md),
        child: Row(
          mainAxisAlignment: forward
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          spacing: CajuiSpacing.sm,
          children: forward
              ? [Flexible(child: words), icon]
              : [icon, Flexible(child: words)],
        ),
      ),
    );
  }

  /// "PRÓXIMA" pequeno em cima, o nome da página embaixo.
  Widget _words(CajuiThemeData theme, String where) => Column(
    crossAxisAlignment: forward
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        where.toUpperCase(),
        style: theme.typography.overline.copyWith(
          color: theme.colors.text.faint,
        ),
      ),
      Text(
        destination.title,
        textAlign: forward ? TextAlign.end : TextAlign.start,
        style: theme.typography.bodyStrong.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
    ],
  );
}
