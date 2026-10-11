import 'package:design_system/src/components/amount/cajui_amount_text.dart';
import 'package:design_system/src/components/amount/cajui_amount_tone.dart';
import 'package:design_system/src/components/credit_card/card_limit_usage.dart';
import 'package:design_system/src/components/credit_card/card_sheen.dart';
import 'package:design_system/src/components/credit_card/credit_card_front.dart';
import 'package:design_system/src/components/meter/cajui_meter.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O verso do cartão: quanto do limite está em uso, quanto está livre, a
/// barra e a frase que descreve o momento.
///
/// A barra nunca vem sozinha (RN-862): o percentual e a frase ficam logo
/// abaixo, em texto.
class CreditCardBack extends StatelessWidget {
  /// Cria o verso do cartão [name] com o [usage] do limite.
  const new({
    required this.name,
    required this.usage,
    required this.light,
    super.key,
  });

  /// O nome do cartão.
  final String name;

  /// O uso do limite.
  final CardLimitUsage usage;

  /// Onde a luz bate.
  final Alignment light;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        // A superfície de cartão, e não a mais alta: no escuro ela é a mais
        // funda das duas, e só nela o texto de apoio aguenta o brilho por
        // cima (4,96:1 contra 4,21:1 na mais alta).
        color: colors.surface.elevated,
        borderRadius: CreditCardFront.radius,
        border: Border.all(color: colors.border.subtle),
        boxShadow: CreditCardFront.shadowOf(colors.brightness),
      ),
      child: ClipRRect(
        borderRadius: CreditCardFront.radius,
        child: Stack(
          children: [
            Positioned.fill(child: CardSheen(light: light)),
            Padding(
              padding: const EdgeInsets.all(CajuiSpacing.xl),
              child: _content(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(CajuiThemeData theme) {
    final muted = theme.colors.text.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Limite do $name',
          style: theme.typography.label.copyWith(color: muted),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        _figures(theme),
        const SizedBox(height: CajuiSpacing.md),
        CajuiMeter(
          value: usage.fraction,
          fill: usage.fill(theme.colors),
          semanticLabel: 'Limite do $name',
          semanticValue: usage.spoken,
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Text(
          '${usage.percent}% do limite · ${usage.note}',
          style: theme.typography.caption.copyWith(color: muted),
        ),
      ],
    );
  }

  /// Em uso e livre, lado a lado: os dois números que somam o limite.
  Widget _figures(CajuiThemeData theme) {
    return Row(
      children: [
        Expanded(child: _figure(theme, 'Em uso', usage.usedCents)),
        Expanded(
          child: _figure(
            theme,
            'Livre',
            usage.freeCents,
            tone: CajuiAmountTone.positive,
          ),
        ),
      ],
    );
  }

  Widget _figure(
    CajuiThemeData theme,
    String label,
    int cents, {
    CajuiAmountTone tone = CajuiAmountTone.neutral,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typography.caption.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        CajuiAmountText(cents, tone: tone),
      ],
    );
  }
}
