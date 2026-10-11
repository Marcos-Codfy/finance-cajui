import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/semantic/brand_colors.dart';
import 'package:flutter/widgets.dart';

/// A luz que bate no cartão: uma mancha macia que anda ao contrário da
/// inclinação, como o reflexo de uma lâmpada no teto.
///
/// Fica por baixo do texto, nunca por cima, e no máximo a
/// `BrandColors.sheenOverText`: brilho que apaga o número não é brilho.
class CardSheen extends StatelessWidget {
  /// Desenha o brilho com o centro em [light].
  const new({required this.light, super.key});

  /// Onde a luz está mais forte, em coordenadas de alinhamento.
  final Alignment light;

  @override
  Widget build(BuildContext context) {
    final sheen = CajuiTheme.of(context).colors.brand.sheen;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: light,
            radius: 0.95,
            colors: [
              sheen.withValues(alpha: BrandColors.sheenOverText),
              sheen.withValues(alpha: BrandColors.sheenOverText * 0.4),
              sheen.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
