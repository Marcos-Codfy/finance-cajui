import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Vencimentos do mês", no Meu mês (17/10/2026): as contas com dia, pagas e
/// a pagar, na linha do tempo — o mesmo "o que falta pagar" que a Juju
/// responde, à vista. Quem diz o que está pago é o domínio (`MonthBills`).
class MonthTimeline extends ConsumerWidget {
  /// Cria a linha do tempo de [month].
  const new({required this.month, super.key});

  /// O mês.
  final BudgetMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finances = ref.watch(financesProvider);
    final book = ref.watch(ledgerProvider).value;
    if (finances == null || book == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    final bills = MonthBills.of(
      finances,
      month,
      cardIds: {for (final card in book.cards) card.id},
    );
    if (bills.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CajuiSectionTitle('Vencimentos do mês'),
        CajuiTimeline(items: [for (final bill in bills) _item(bill, today)]),
      ],
    );
  }

  static CajuiTimelineItem _item(MonthBill bill, LocalDate today) {
    final day = bill.dueOn.day;
    final late = !bill.paid && today.isAfter(bill.dueOn);
    return CajuiTimelineItem(
      title: bill.line.name,
      subtitle: switch ((bill.paid, late)) {
        (true, _) => 'vence dia $day · paga',
        (false, true) => 'venceu dia $day · a pagar',
        (false, false) => 'vence dia $day · a pagar',
      },
      cents: bill.line.amount.cents,
      mark: bill.paid
          ? CajuiTimelineMark.done
          : late
          ? CajuiTimelineMark.late
          : CajuiTimelineMark.pending,
    );
  }
}
