import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma seção de página: título, explicação opcional e o conteúdo.
class GallerySection extends StatelessWidget {
  /// Cria a seção [title] com o conteúdo [child].
  const new({
    required this.title,
    required this.child,
    this.description,
    super.key,
  });

  /// O título da seção.
  final String title;

  /// Por que a seção existe, ou o que observar nela.
  final String? description;

  /// O conteúdo.
  final Widget child;

  Widget _heading(CajuiThemeData theme) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: theme.typography.title.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final note = description;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.block),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(theme),
          if (note != null) ...[
            const SizedBox(height: CajuiSpacing.xs),
            Text(
              note,
              style: theme.typography.caption.copyWith(
                color: theme.colors.text.muted,
              ),
            ),
          ],
          const SizedBox(height: CajuiSpacing.lg),
          child,
        ],
      ),
    );
  }
}
