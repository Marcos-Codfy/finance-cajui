import 'package:design_system/src/components/confidence/cajui_confidence_level.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Mostra com que certeza um campo foi preenchido: três pontos e uma frase.
///
/// A confiança nunca é dita só por cor nem só pelos pontos — a frase está
/// sempre lá (RNF-A11Y-03). É ela que o leitor de tela anuncia; os pontos são
/// decorativos para ele.
class CajuiConfidenceIndicator extends StatelessWidget {
  /// Mostra o nível [level].
  const new(this.level, {super.key});

  /// A zona de confiança.
  final CajuiConfidenceLevel level;

  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                _dotAt(
                  filled: i < level.filledDots,
                  on: colors.text.muted,
                  off: colors.border.field,
                ),
            ],
          ),
        ),
        const SizedBox(width: CajuiSpacing.sm),
        Text(
          level.label,
          style: theme.typography.caption.copyWith(color: colors.text.muted),
        ),
      ],
    );
  }

  /// Ponto cheio ou só o contorno: a diferença é de forma, não de cor.
  Widget _dotAt({required bool filled, required Color on, required Color off}) {
    return Padding(
      padding: const EdgeInsets.only(right: CajuiSpacing.xxs + 1),
      child: SizedBox.square(
        dimension: _dot,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? on : null,
            border: Border.all(color: filled ? on : off, width: 1.5),
          ),
        ),
      ),
    );
  }
}
