import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Um cartão de número: o que é, quanto é e, se preciso, uma frase de apoio
/// e um medidor. É a peça que mais se repete nas telas do Cajui.
class StatCard extends StatelessWidget {
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

  /// O que o número é: "Dá para gastar esta semana".
  final String label;

  /// O valor em centavos. Sem valor, aparece um travessão: o número é
  /// indefinido, e não zero (RN-604).
  final int? cents;

  /// O papel do número.
  final CajuiAmountTone tone;

  /// Número-manchete.
  final bool large;

  /// A frase de apoio, embaixo do número.
  final String? caption;

  /// A fração usada de um limite, quando o número é parte de um todo.
  final double? meter;

  /// Cartão rebaixado, para o que é secundário.
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
            if (used != null) ...[
              const SizedBox(height: CajuiSpacing.md),
              CajuiMeter(
                value: used,
                semanticLabel: label,
                semanticValue: support ?? '',
              ),
            ],
            if (support != null) ...[
              const SizedBox(height: CajuiSpacing.sm),
              Text(support, style: _muted(theme, theme.typography.caption)),
            ],
          ],
        ),
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
