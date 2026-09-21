import 'package:design_system/src/components/amount/cajui_amount_text.dart';
import 'package:design_system/src/components/amount/cajui_amount_tone.dart';
import 'package:design_system/src/components/card/cajui_card.dart';
import 'package:design_system/src/components/meter/cajui_meter.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Um número do painel: o que ele mede, o valor e, se couber, quanto do todo
/// ele já tomou.
///
/// Não existe cartão "vermelho" nem cartão "verde": o tom é o **papel** do
/// número — sobra, falta, moeda do vale —, e a leitura de bom ou ruim fica
/// com a frase de apoio, que diz o que fazer com ele.
class CajuiStatCard extends StatelessWidget {
  /// Cria o cartão do número [label].
  const new({
    required this.label,
    this.cents,
    this.tone = CajuiAmountTone.neutral,
    this.large = false,
    this.caption,
    this.meter,
    this.sunken = false,
    super.key,
  });

  /// O que o número mede.
  final String label;

  /// O valor, em centavos. `null` quando ainda não dá para calcular — sem
  /// renda cadastrada, por exemplo —, e o cartão mostra um travessão.
  final int? cents;

  /// O papel do valor.
  final CajuiAmountTone tone;

  /// Se este é o número principal da tela.
  final bool large;

  /// A frase de apoio.
  final String? caption;

  /// Quanto do todo já foi usado, de 0 a 1 ou mais. Com isto, o cartão ganha
  /// a barra — que exige [caption], o mesmo dado em texto (RN-862).
  final double? meter;

  /// Rebaixado: para a moeda que fica ao lado, o vale.
  final bool sunken;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final support = caption;
    final used = meter;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.lg),
      child: CajuiCard(
        sunken: sunken,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _muted(theme, theme.typography.label)),
            const SizedBox(height: CajuiSpacing.xs),
            _amount(theme),
            if (used != null) _meter(used),
            if (support != null) ...[
              const SizedBox(height: CajuiSpacing.sm),
              Text(support, style: _muted(theme, theme.typography.caption)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _meter(double used) {
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.md),
      child: CajuiMeter(
        value: used,
        semanticLabel: label,
        semanticValue: caption ?? '',
      ),
    );
  }

  TextStyle _muted(CajuiThemeData theme, TextStyle style) =>
      style.copyWith(color: theme.colors.text.muted);

  Widget _amount(CajuiThemeData theme) {
    final value = cents;
    if (value != null) {
      return CajuiAmountText(value, tone: tone, large: large);
    }
    return Semantics(
      label: 'Ainda sem valor',
      excludeSemantics: true,
      child: Text(
        '—',
        style: theme.typography.amountLarge.copyWith(
          color: theme.colors.text.faint,
        ),
      ),
    );
  }
}
