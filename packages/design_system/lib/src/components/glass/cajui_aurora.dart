import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:flutter/widgets.dart';

/// A aurora do Cerrado à noite: o céu de `brand.auroraSky` com as três luzes
/// de `brand.aurora` — o cajuí no alto à esquerda, o capim dourado à
/// direita, a vereda embaixo —, todas difusas, sem contorno.
///
/// É o fundo do widget da tela inicial; o `home_widget_aurora.xml` do
/// Android desenha a mesma composição, com os mesmos valores. Sobre ela, o
/// vidro (`CajuiGlassPanel`) parece fosco sem desfocar nada: o que está
/// atrás já não tem borda.
class CajuiAurora extends StatelessWidget {
  /// Pinta a aurora atrás de [child], com os cantos em [radius].
  const new({required this.child, this.radius = CajuiRadius.xl, super.key});

  /// O que fica por cima.
  final Widget child;

  /// O raio dos cantos.
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    final brand = CajuiTheme.of(context).colors.brand;
    final [warm, gold, vereda] = brand.aurora;
    return ClipRRect(
      borderRadius: BorderRadius.all(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: brand.auroraSky,
          ),
        ),
        child: Stack(
          children: [
            _light(warm, const Alignment(-1.1, -1.4), 0.8),
            _light(gold, const Alignment(1.25, 0), 0.7),
            _light(vereda, const Alignment(0, 1.6), 0.6),
            child,
          ],
        ),
      ),
    );
  }

  /// Uma luz difusa centrada em [at], forte no miolo e nula na borda.
  static Widget _light(Color color, Alignment at, double strength) =>
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: at,
                radius: 0.95,
                colors: [
                  color.withValues(alpha: strength),
                  color.withValues(alpha: strength * 0.4),
                  color.withValues(alpha: 0),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
      );
}
