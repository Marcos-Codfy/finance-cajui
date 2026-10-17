import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O widget pequeno da tela inicial (2×1), como o Android o desenha: o
/// mesmo vidro sobre a aurora do grande, só com o rótulo e o número.
///
/// É a réplica do `home_widget_small.xml`. O número encolhe para caber
/// inteiro, como o `autoSizeTextType` do Android: um valor cortado no meio
/// diria outro valor.
class GlassWidgetSmall extends StatelessWidget {
  /// Cria o widget com [label] e [amount], como o app publica.
  const new({
    required this.label,
    required this.amount,
    this.onNumber,
    super.key,
  });

  /// "Sobra de outubro".
  final String label;

  /// O valor já escrito: "R$ 1.312,40".
  final String amount;

  /// O toque no widget: abre o app pela mesma chegada do grande.
  final VoidCallback? onNumber;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 96,
      child: CajuiAurora(
        child: Stack(
          children: [
            Positioned.fill(child: _glass(context)),
            const Positioned(
              top: 2,
              right: 2,
              child: CajuiOrb(size: 22, tone: CajuiOrbTone.vereda),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glass(BuildContext context) => Padding(
    padding: const EdgeInsets.all(CajuiSpacing.sm),
    child: CajuiPressable(
      onPressed: onNumber,
      semanticLabel: '$label: $amount. Abrir o Cajui',
      touch: CajuiTouch.card,
      builder: (context, _) => CajuiGlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: _number(context),
      ),
    ),
  );

  Widget _number(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final light = theme.colors.brand.sheen;
    final type = theme.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.overline.copyWith(color: light.withValues(alpha: 0.8)),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(amount, style: type.amountLarge.copyWith(color: light)),
        ),
      ],
    );
  }
}
