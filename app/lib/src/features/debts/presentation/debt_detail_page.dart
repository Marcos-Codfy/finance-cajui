import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/debts/presentation/debt_kind_label.dart';
import 'package:cajui/src/features/debts/presentation/debt_payment_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_payoff_section.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
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
    final debt = ref.watch(ledgerProvider).value?.debtOf(debtId);
    if (debt == null) return const SizedBox.shrink();
    final today = ref.watch(clockProvider).today();
    return CajuiScreen(
      title: debt.creditor,
      onBack: Navigator.of(context).pop,
      footer: _payButton(context, debt),
      children: [
        CajuiStatCard(
          label: 'Falta pagar',
          cents: debt.outstandingBalance.cents,
          large: true,
          caption: _caption(debt),
          // O medidor é secundário e conta desde o começo (RN-541).
          meter: debt.paidInstallments / debt.totalInstallments,
        ),
        const CajuiSectionTitle('Como está'),
        ..._facts(debt, today),
        ...DebtPayoffSection.of(debt, today: today),
      ],
    );
  }

  static String _caption(Debt debt) {
    if (debt.isPaidOff) return 'Quitada. Fica no histórico.';
    final forecast = DateLabels.month(debt.payoffForecast);
    return 'No ritmo atual, quita em $forecast';
  }

  List<Widget> _facts(Debt debt, LocalDate today) => [
    CajuiListRow(
      title: 'Parcela',
      subtitle: 'vence dia ${debt.dueDay} · ${DebtKindLabel.of(debt.kind)}',
      trailing: CajuiAmountText(debt.installmentAmount.cents),
    ),
    CajuiListRow(
      title: 'Já pago',
      subtitle:
          '${debt.paidInstallments} de ${debt.totalInstallments} parcelas',
      trailing: CajuiAmountText(debt.paidSoFar.cents),
    ),
  ];

  /// Parcelamento de compra no cartão não tem botão de pagar: a parcela é
  /// cobrada na fatura, e lançá-la de novo contaria duas vezes (RN-521).
  Widget? _payButton(BuildContext context, Debt debt) {
    if (debt.isPaidOff || debt.kind == DebtKind.cardInstallment) return null;
    return CajuiButton(
      label: 'Paguei a parcela deste mês',
      expand: true,
      onPressed: () => DebtPaymentPage.open(context, debt),
    );
  }
}
