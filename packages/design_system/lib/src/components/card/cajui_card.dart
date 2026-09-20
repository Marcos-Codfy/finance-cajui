import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_shadows.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O cartão: a superfície elevada que agrupa um assunto.
///
/// No tema claro a elevação vem da sombra; no escuro, da superfície mais
/// clara — sombra quase não se vê sobre azul-petróleo.
///
/// Com [onPressed], o cartão inteiro vira um controle, e então
/// [semanticLabel] é obrigatório: o leitor de tela precisa de um nome só, e
/// não de cada texto de dentro lido em sequência.
class CajuiCard extends StatelessWidget {
  /// Cria um cartão em volta de [child].
  const new({
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.sunken = false,
    this.padding = const EdgeInsets.all(CajuiSpacing.xl),
    super.key,
  }) : assert(
         onPressed == null || semanticLabel != null,
         'Cartão tocável precisa de semanticLabel.',
       );

  /// O conteúdo.
  final Widget child;

  /// Torna o cartão inteiro tocável.
  final VoidCallback? onPressed;

  /// O nome do cartão para o leitor de tela, quando tocável.
  final String? semanticLabel;

  /// Cartão rebaixado: sem sombra, na cor `surface.sunken`.
  final bool sunken;

  /// O respiro interno.
  final EdgeInsetsGeometry padding;

  static const _radius = BorderRadius.all(CajuiRadius.xl);

  @override
  Widget build(BuildContext context) {
    final tap = onPressed;
    if (tap == null) return _surface(context, lifted: false);
    return CajuiPressable(
      onPressed: tap,
      radius: _radius,
      semanticLabel: semanticLabel!,
      builder: (context, states) => _surface(
        context,
        lifted: states.contains(WidgetState.hovered),
      ),
    );
  }

  Widget _surface(BuildContext context, {required bool lifted}) {
    final colors = CajuiTheme.of(context).colors;
    final light = colors.brightness == Brightness.light;
    final shadow = lifted ? CajuiShadows.floating : CajuiShadows.raised;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sunken ? colors.surface.sunken : colors.surface.elevated,
        borderRadius: _radius,
        border: Border.all(color: colors.border.subtle),
        boxShadow: light && !sunken ? shadow : CajuiShadows.none,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
