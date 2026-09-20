import 'package:design_system/src/components/amount/cajui_amount_tone.dart';
import 'package:design_system/src/format/brl_formatter.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// Um valor em reais, sempre com algarismos tabulares.
///
/// Recebe centavos inteiros. O "R$" aparece menor e mais claro quando o
/// número é grande, e do mesmo tamanho em lista — como manda o guia de
/// tipografia.
class CajuiAmountText extends StatelessWidget {
  /// Mostra [cents] em reais.
  const new(
    this.cents, {
    this.tone = CajuiAmountTone.neutral,
    this.large = false,
    this.hideZeroCents = false,
    super.key,
  });

  /// O valor, em centavos.
  final int cents;

  /// O que o valor está dizendo.
  final CajuiAmountTone tone;

  /// Valor em destaque (28 px) em vez de valor de lista (16 px).
  final bool large;

  /// Omite ",00": só para número-manchete.
  final bool hideZeroCents;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final typography = theme.typography;
    final base = large ? typography.amountLarge : typography.amount;
    final color = tone.resolve(theme.colors);
    final number = BrlFormatter.number(cents, hideZeroCents: hideZeroCents);
    final sign = cents < 0 ? BrlFormatter.minus : '';
    return Text.rich(
      TextSpan(
        children: [
          _currency(base, faint: theme.colors.text.faint, same: color, sign),
          TextSpan(text: number, style: base.copyWith(color: color)),
        ],
      ),
      semanticsLabel: BrlFormatter.format(cents),
      maxLines: 1,
    );
  }

  /// "R$" menor e mais claro no valor grande; igual ao número na lista.
  TextSpan _currency(
    TextStyle base,
    String sign, {
    required Color faint,
    required Color same,
  }) {
    final style = large
        ? base.copyWith(fontSize: base.fontSize! * 0.5, color: faint)
        : base.copyWith(color: same);
    return TextSpan(text: '${sign}R\$${BrlFormatter.nbsp}', style: style);
  }
}
