import 'package:design_system/src/components/glass/cajui_orb_tone.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// A esfera que flutua sobre o vidro do widget, com o reflexo de uma janela
/// no alto. É o toque surreal: um fruto de luz suspenso, maior que a vida,
/// fora do painel. O `home_widget_orb.xml` do Android é a mesma esfera.
///
/// Enfeite puro: não tem nome para o leitor de tela.
class CajuiOrb extends StatelessWidget {
  /// Desenha a esfera com [size] de diâmetro.
  const new({this.size = 40, this.tone = CajuiOrbTone.fruit, super.key});

  /// O diâmetro.
  final double size;

  /// De que é feita.
  final CajuiOrbTone tone;

  @override
  Widget build(BuildContext context) {
    final brand = CajuiTheme.of(context).colors.brand;
    final colors = switch (tone) {
      CajuiOrbTone.fruit => brand.fruitGradient,
      CajuiOrbTone.vereda => [
        brand.sheen,
        brand.aurora.last,
        brand.auroraSky.first,
      ],
    };
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 0.9,
              colors: colors,
            ),
          ),
          child: Align(
            alignment: const Alignment(-0.45, -0.55),
            child: _window(brand.sheen),
          ),
        ),
      ),
    );
  }

  /// O reflexo da janela: uma mancha clara, oval, no alto à esquerda.
  Widget _window(Color sheen) => SizedBox(
    width: size * 0.42,
    height: size * 0.28,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(size, size)),
        gradient: RadialGradient(
          colors: [sheen.withValues(alpha: 0.85), sheen.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
