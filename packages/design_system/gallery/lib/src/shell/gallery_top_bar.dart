import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// O alto da gallery no celular: onde se está, o menu e os ajustes.
///
/// Substitui a fileira de 26 chips, que não cabia na tela, não tinha grupos
/// e escondia a página aberta para a direita — foi por ela que o dono não
/// achou a página de estados. Agora são duas peças: "Páginas" abre o menu
/// inteiro, agrupado como no computador, e o botão de ajustes abre o resto.
class GalleryTopBar extends StatelessWidget {
  /// Cria o alto com a página [page] aberta.
  const new({
    required this.page,
    required this.onPages,
    required this.onSettings,
    super.key,
  });

  /// A página aberta.
  final GalleryDestination page;

  /// Abre o menu.
  final VoidCallback onPages;

  /// Abre os ajustes.
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CajuiSpacing.lg,
        CajuiSpacing.sm,
        CajuiSpacing.xs,
        CajuiSpacing.sm,
      ),
      child: Row(
        spacing: CajuiSpacing.xs,
        children: [
          Expanded(child: _where(theme)),
          CajuiButton(
            label: 'Páginas',
            variant: CajuiButtonVariant.secondary,
            size: CajuiButtonSize.compact,
            onPressed: onPages,
          ),
          CajuiIconButton(
            icon: CajuiIconData.sliders,
            semanticLabel: 'Ajustes: tema, som e movimento',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }

  /// "CAJUI · DESIGN SYSTEM" pequeno, e embaixo a página aberta.
  Widget _where(CajuiThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'CAJUI · DESIGN SYSTEM',
        style: theme.typography.overline.copyWith(
          color: theme.colors.text.faint,
        ),
      ),
      Text(
        page.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.typography.bodyStrong.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
    ],
  );
}
