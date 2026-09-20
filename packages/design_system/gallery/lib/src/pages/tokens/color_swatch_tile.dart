import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma amostra de cor: o bloco pintado, o nome do papel e o valor.
class ColorSwatchTile extends StatelessWidget {
  /// Cria a amostra do papel [name] com a cor [color].
  const new({required this.name, required this.color, super.key});

  /// O nome do papel, como o código escreve: `action.primary`.
  final String name;

  /// A cor do papel no tema em vigor.
  final Color color;

  static const double _width = 176;
  static const double _blockHeight = 72;

  /// O valor em hexadecimal; a opacidade só aparece quando não é total.
  String get _hex {
    final argb = color.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final alpha = (color.a * 100).round();
    final suffix = alpha == 100 ? '' : ' · $alpha%';
    return '#${rgb.toUpperCase()}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      label: '$name, $_hex',
      excludeSemantics: true,
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _block(theme.colors),
            const SizedBox(height: CajuiSpacing.sm),
            Text(
              name,
              style: theme.typography.label.copyWith(
                color: theme.colors.text.primary,
              ),
            ),
            Text(
              _hex,
              style: theme.typography.caption.copyWith(
                color: theme.colors.text.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A borda existe para a amostra não sumir quando a cor é a do fundo.
  Widget _block(CajuiColors colors) {
    return Container(
      height: _blockHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(CajuiRadius.sm),
        border: Border.all(color: colors.border.subtle),
      ),
    );
  }
}
