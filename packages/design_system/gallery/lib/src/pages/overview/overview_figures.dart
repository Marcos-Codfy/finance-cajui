import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// Os números da porta de entrada, contados do código, e não escritos à mão:
/// página nova, som novo ou par de cor novo mudam o número sozinhos.
class OverviewFigures extends StatelessWidget {
  /// Cria os números.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    final pairs = ContrastAudit.pairsFor(colors);
    final passing = pairs.where((pair) => pair.passes).length;
    final figures = [
      ('${GalleryDestination.values.length}', 'páginas navegáveis'),
      ('$passing de ${pairs.length}', 'pares de cor no contraste AA'),
      ('${CajuiSound.values.length}', 'sons, cada um com um papel'),
      ('${MotionLevel.values.length}', 'níveis de movimento'),
      ('${CajuiIconData.values.length}', 'ícones desenhados em código'),
    ];
    return Wrap(
      spacing: CajuiSpacing.xxl,
      runSpacing: CajuiSpacing.xl,
      children: [
        for (final (value, label) in figures)
          _Figure(value: value, label: label),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const new({required this.value, required this.label});

  final String value;
  final String label;

  static const double _width = 150;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return SizedBox(
      width: _width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.typography.displayMedium.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          Text(
            label,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ],
      ),
    );
  }
}
