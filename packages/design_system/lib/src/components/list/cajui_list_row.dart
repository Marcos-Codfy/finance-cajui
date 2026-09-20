import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Uma linha de lista: o lançamento, a parcela, o item de configuração.
///
/// A estrutura espelha a regra central do produto: o título é **o que foi
/// comprado**; o subtítulo, **por onde foi pago**.
class CajuiListRow extends StatelessWidget {
  /// Cria uma linha com [title] e, opcionalmente, o resto.
  const new({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    this.semanticLabel,
    super.key,
  }) : assert(
         onPressed == null || semanticLabel != null,
         'Linha tocável precisa de semanticLabel.',
       );

  /// O que foi: "Mercado".
  final String title;

  /// Por onde foi pago, ou outro apoio: "Vale alimentação".
  final String? subtitle;

  /// O que vem antes: ícone ou emoji de categoria.
  final Widget? leading;

  /// O que vem depois: valor, chave, seta.
  final Widget? trailing;

  /// Torna a linha tocável.
  final VoidCallback? onPressed;

  /// O nome completo da linha para o leitor de tela, quando tocável:
  /// "Mercado, vale alimentação, R$ 38,40".
  final String? semanticLabel;

  static const _radius = BorderRadius.all(CajuiRadius.md);
  static const double _leadingBox = 40;

  @override
  Widget build(BuildContext context) {
    final tap = onPressed;
    if (tap == null) return _row(context);
    return CajuiPressable(
      onPressed: tap,
      radius: _radius,
      semanticLabel: semanticLabel!,
      builder: (context, _) => _row(context),
    );
  }

  Widget _row(BuildContext context) {
    final before = leading;
    final after = trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CajuiSpacing.sm),
      child: Row(
        children: [
          if (before != null) ...[
            _leading(context, before),
            const SizedBox(width: CajuiSpacing.md),
          ],
          Expanded(child: _texts(context)),
          if (after != null) ...[
            const SizedBox(width: CajuiSpacing.md),
            after,
          ],
        ],
      ),
    );
  }

  Widget _leading(BuildContext context, Widget child) {
    final colors = CajuiTheme.of(context).colors;
    return SizedBox.square(
      dimension: _leadingBox,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.sunken,
          borderRadius: const BorderRadius.all(CajuiRadius.sm),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _texts(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final support = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.typography.body.copyWith(
            color: theme.colors.text.primary,
            fontVariations: const [FontVariation('wght', 500)],
          ),
        ),
        if (support != null)
          Text(
            support,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
      ],
    );
  }
}
