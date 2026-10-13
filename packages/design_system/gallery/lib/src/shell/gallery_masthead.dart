import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O nome no alto do menu do computador.
class GalleryMasthead extends StatelessWidget {
  /// Cria o nome.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CajuiSpacing.xxl,
        CajuiSpacing.xxl,
        CajuiSpacing.xxl,
        CajuiSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cajui',
            style: theme.typography.headline.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          Text(
            'Design system · por Marcos Vinicius',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
        ],
      ),
    );
  }
}
