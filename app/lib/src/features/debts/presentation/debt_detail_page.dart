import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/debts/presentation/debt_actions.dart';
import 'package:cajui/src/features/debts/presentation/debt_kind_label.dart';
import 'package:cajui/src/features/debts/presentation/debt_payoff_section.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uma dívida por inteiro: onde ela está, quando termina e o que dá para
/// fazer com ela.
///
/// O número em destaque é **o saldo nominal** — a soma das parcelas que
/// faltam (RN-510) —, porque não depende de dado que a pessoa talvez não
/// tenha. O valor para quitar hoje, quando existe, aparece à parte, com a
/// data em que o credor informou (RN-511).
class DebtDetailPage extends ConsumerWidget {
  /// Cria a tela da dívida [debtId].
  const new({required this.debtId, super.key});

  /// A dívida à vista.
  final String debtId;

  /// Abre a tela.
  static Future<void> open(BuildContext context, String debtId) {
    return Navigator.of(context).push<void>(
      CajuiPageRoute(builder: (_) => DebtDetailPage(debtId: debtId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(ledgerProvider).value?.debtOf(debtId);
    if (saved == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    // A dívida como está hoje: na parcelada, o calendário já venceu parcelas
    // que o cadastro não contava, e "já pago", o medidor e "terminar antes"
    // precisam vê-las, como o "ainda devo" (RN-1030).
    final debt = DebtCalendar.asOf(saved, today);
    final owed = DebtCalendar.outstandingOn(debt, today);
    return CajuiScreen(
      title: debt.creditor,
      onBack: Navigator.of(context).pop,
      footer: DebtActions(debt: debt, owed: owed),
      children: [
        _owedCard(debt, owed),
        const CajuiSectionTitle('Como está'),
        ..._facts(debt),
        ...DebtPayoffSection.of(debt, today: today),
      ],
    );
  }

  static Widget _owedCard(Debt debt, Money owed) => CajuiStatCard(
    label: 'Ainda devo',
    cents: owed.cents,
    large: true,
    caption: _caption(debt, owed),
    // O medidor é secundário e conta desde o começo (RN-541); só a
    // parcelada tem começo e fim para medir.
    meter: debt.informedBalance == null && debt.totalInstallments > 0
        ? debt.paidInstallments / debt.totalInstallments
        : null,
  );

  static String _caption(Debt debt, Money owed) {
    if (owed.isZero) return 'Quitada. Fica no histórico.';
    if (!debt.installmentAmount.isPositive) {
      return 'Sem parcela por mês: o saldo fica até ser negociado.';
    }
    final forecast = DateLabels.month(debt.payoffForecast);
    return 'No ritmo atual, quita em $forecast';
  }

  List<Widget> _facts(Debt debt) => [
    CajuiListRow(
      title: 'Por mês',
      subtitle: 'vence dia ${debt.dueDay} · ${DebtKindLabel.of(debt.kind)}',
      trailing: CajuiAmountText(debt.installmentAmount.cents),
    ),
    if (debt.informedBalance == null)
      CajuiListRow(
        title: 'Já pago',
        subtitle:
            '${debt.paidInstallments} de ${debt.totalInstallments} parcelas',
        trailing: CajuiAmountText(debt.paidSoFar.cents),
      ),
    if (debt.note case final note?)
      CajuiListRow(title: 'Observação', subtitle: note),
  ];
}
