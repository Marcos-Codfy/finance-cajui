import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O widget da tela inicial, como o Android o desenha: o vidro sobre a
/// aurora, as duas esferas de luz, o número e os dois atalhos.
///
/// É a réplica do `home_widget.xml`, feita só com os componentes do design
/// system: a aurora (`CajuiAurora`), o vidro (`CajuiGlassPanel`) e as
/// esferas (`CajuiOrb`). O número é tocável — no aparelho, ele abre o app
/// com a chegada pelo vidro.
class GlassWidget extends StatelessWidget {
  /// Cria o widget com [label], [amount] e [caption], como o app publica.
  const new({
    required this.label,
    required this.amount,
    required this.caption,
    this.onNumber,
    super.key,
  });

  /// "Sobra de outubro".
  final String label;

  /// O valor já escrito: "R$ 1.312,40".
  final String amount;

  /// A frase de baixo.
  final String caption;

  /// O toque no número.
  final VoidCallback? onNumber;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: CajuiAurora(
        child: Stack(
          children: [
            const Positioned(
              left: 18,
              bottom: 4,
              child: CajuiOrb(size: 22, tone: CajuiOrbTone.vereda),
            ),
            Positioned.fill(child: _glass(context)),
            const Positioned(top: 2, right: 64, child: CajuiOrb()),
          ],
        ),
      ),
    );
  }

  /// O vidro, a uma margem da aurora, com o número e os atalhos.
  Widget _glass(BuildContext context) => Padding(
    padding: const EdgeInsets.all(CajuiSpacing.sm),
    child: CajuiGlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      child: Row(
        children: [
          Expanded(child: _number(context)),
          _shortcuts(context),
        ],
      ),
    ),
  );

  Widget _number(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final light = theme.colors.brand.sheen;
    final muted = light.withValues(alpha: 0.8);
    final type = theme.typography;
    return CajuiPressable(
      onPressed: onNumber,
      semanticLabel: '$label: $amount. Abrir o Cajui',
      touch: CajuiTouch.card,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: type.overline.copyWith(color: muted),
          ),
          Text(amount, style: type.amountLarge.copyWith(color: light)),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: type.caption.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  Widget _shortcuts(BuildContext context) {
    final light = CajuiTheme.of(context).colors.brand.sheen;
    Widget button(CajuiIconData icon, String name) => Semantics(
      button: true,
      label: name,
      child: SizedBox.square(
        dimension: 44,
        child: CajuiGlassPanel(
          round: true,
          padding: const EdgeInsets.all(10),
          child: CajuiIcon(icon, color: light),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(CajuiIconData.camera, 'Fotografar comprovante'),
        const SizedBox(height: CajuiSpacing.sm),
        button(CajuiIconData.image, 'Escolher da galeria'),
      ],
    );
  }
}
