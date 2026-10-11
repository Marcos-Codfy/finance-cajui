import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Uma dívida na lista, como na planilha: para quem, quanto ainda devo,
/// quanto pago por mês, de que tipo — e a posição na fila de quitação.
///
/// O número que vem primeiro é o que falta, nunca bronca (RN-541, RN-542).
class DebtRow extends StatelessWidget {
  /// Cria a linha de [debt], que ainda deve [owed].
  const new({
    required this.debt,
    required this.owed,
    required this.onPressed,
    this.position,
    super.key,
  });

  /// A dívida.
  final Debt debt;

  /// Quanto ainda se deve hoje, pelo calendário (RN-1030).
  final Money owed;

  /// A posição na ordem de quitação; nula para a quitada.
  final int? position;

  /// O que fazer ao tocar: abrir a dívida.
  final VoidCallback onPressed;

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  String get _type => switch (debt.type) {
    DebtType.installments => 'Parcelado',
    DebtType.overdue => 'Atrasado',
    DebtType.revolving => 'Rotativo',
  };

  String get _headline {
    if (owed.isZero) return 'Quitada';
    final perMonth = debt.installmentAmount.isPositive
        ? '${_brl(debt.installmentAmount)} por mês'
        : 'sem parcela ainda';
    return 'Devo ${_brl(owed)} · $perMonth';
  }

  @override
  Widget build(BuildContext context) {
    final place = position == null ? '' : '$positionº · ';
    final note = debt.note == null ? '' : ' · ${debt.note}';
    final subtitle = '$place$_type · $_headline$note';
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
      child: CajuiListRow(
        title: debt.creditor,
        subtitle: subtitle,
        trailing: const CajuiIcon(CajuiIconData.chevronRight),
        semanticLabel: '${debt.creditor}, $subtitle, abrir',
        onPressed: onPressed,
      ),
    );
  }
}
