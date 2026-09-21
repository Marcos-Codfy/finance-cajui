import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Uma dívida na lista.
///
/// O número vem primeiro e é **o que falta** — "faltam 7 parcelas de
/// R$ 212,00" —, com o já pago ao lado; o medidor é secundário e conta desde
/// o começo (RN-541). Nenhum texto aqui atribui falha a quem deve (RN-542).
class DebtRow extends StatelessWidget {
  /// Cria a linha de [debt].
  const new({required this.debt, required this.onPressed, super.key});

  /// A dívida.
  final Debt debt;

  /// O que fazer ao tocar: abrir a dívida.
  final VoidCallback onPressed;

  String get _headline {
    if (debt.isPaidOff) return 'Quitada';
    final amount = BrlFormatter.format(debt.installmentAmount.cents);
    final parcels = debt.remainingInstallments == 1
        ? 'Falta 1 parcela'
        : 'Faltam ${debt.remainingInstallments} parcelas';
    return '$parcels de $amount';
  }

  String get _progress =>
      '${debt.paidInstallments} de ${debt.totalInstallments} pagas';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CajuiListRow(
            title: debt.creditor,
            subtitle: '$_headline · $_progress',
            trailing: const CajuiIcon(CajuiIconData.chevronRight),
            semanticLabel: '${debt.creditor}, $_headline, $_progress, abrir',
            onPressed: onPressed,
          ),
          if (!debt.isPaidOff)
            CajuiMeter(
              value: debt.paidInstallments / debt.totalInstallments,
              semanticLabel: 'Parcelas pagas de ${debt.creditor}',
              semanticValue: _progress,
            ),
        ],
      ),
    );
  }
}
