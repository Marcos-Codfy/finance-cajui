import 'package:design_system/src/components/amount/cajui_amount_text.dart';
import 'package:design_system/src/components/amount/cajui_amount_tone.dart';
import 'package:design_system/src/format/brl_formatter.dart';
import 'package:design_system/src/motion/cajui_count_up.dart';
import 'package:flutter/widgets.dart';

/// Um valor em reais que rola até o número certo.
///
/// É o `CajuiAmountText` dentro de um `CajuiCountUp`, com o cuidado que os
/// dois juntos pedem: o leitor de tela ouve só o valor final, uma vez. Sem
/// isso, cada quadro da contagem viraria um anúncio novo — "R$ 12,00, R$
/// 38,00, R$ 71,00…" — num número que a pessoa só quer saber quanto é.
class CajuiRollingAmount extends StatelessWidget {
  /// Mostra [cents] em reais, rolando desde [from] na primeira vez.
  const new(
    this.cents, {
    this.from,
    this.tone = CajuiAmountTone.neutral,
    this.large = false,
    this.hideZeroCents = false,
    super.key,
  });

  /// O valor, em centavos.
  final int cents;

  /// De onde a contagem parte ao aparecer. Sem isto, só rola quando muda.
  final int? from;

  /// O que o valor está dizendo.
  final CajuiAmountTone tone;

  /// Valor em destaque em vez de valor de lista.
  final bool large;

  /// Omite ",00": só para número-manchete.
  final bool hideZeroCents;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: BrlFormatter.format(cents, hideZeroCents: hideZeroCents),
      excludeSemantics: true,
      child: CajuiCountUp(
        value: cents,
        from: from,
        builder: (context, transit) => CajuiAmountText(
          transit,
          tone: tone,
          large: large,
          hideZeroCents: hideZeroCents,
        ),
      ),
    );
  }
}
