import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O painel de vidro, para pôr sobre a `CajuiAurora`: um véu branco
/// translúcido, a borda de luz e o reflexo no alto.
///
/// Não desfoca o que está atrás, de propósito: o widget da tela inicial não
/// pode desfocar o papel de parede (o RemoteViews não sabe), e a réplica
/// aqui tem de ser a mesma coisa que o aparelho mostra. Sobre a aurora,
/// que já é difusa, o vidro parece fosco sem desfoque. O
/// `home_widget_glass.xml` do Android usa os mesmos valores.
///
/// Texto sobre ele vai na cor `brand.sheen`: a aurora é sempre noite.
class CajuiGlassPanel extends StatelessWidget {
  /// Envolve [child] no vidro.
  const new({
    required this.child,
    this.padding = const EdgeInsets.all(CajuiSpacing.md),
    this.radius = CajuiRadius.lg,
    this.round = false,
    super.key,
  });

  /// O conteúdo.
  final Widget child;

  /// O respiro por dentro.
  final EdgeInsetsGeometry padding;

  /// O raio dos cantos, quando não é [round].
  final Radius radius;

  /// Redondo: o botão de vidro.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final sheen = CajuiTheme.of(context).colors.brand.sheen;
    final shape = round
        ? const BoxDecoration(shape: BoxShape.circle)
        : BoxDecoration(borderRadius: BorderRadius.all(radius));
    return DecoratedBox(
      decoration: shape.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sheen.withValues(alpha: 0.22),
            sheen.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: sheen.withValues(alpha: 0.36)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _reflection(shape, sheen)),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  /// A luz que bate no alto do vidro e some no meio.
  static Widget _reflection(BoxDecoration shape, Color sheen) => IgnorePointer(
    child: DecoratedBox(
      decoration: shape.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [sheen.withValues(alpha: 0.16), sheen.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
