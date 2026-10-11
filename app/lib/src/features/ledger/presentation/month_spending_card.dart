import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O gasto do mês, **uma linha por moeda**, e o vale do mês.
///
/// Não há linha de total: dinheiro e vale não se somam em lugar nenhum do
/// Cajui (RN-111). Quem vê "R$ 640" quer saber de qual bolso saiu. O vale é
/// o da planilha, que se muda em Minhas contas — o mesmo número do Início.
class MonthSpendingCard extends StatelessWidget {
  /// Cria o cartão com o gasto [spent] e o vale do mês [voucher].
  const new({required this.spent, required this.voucher, super.key});

  /// O gasto do mês, por moeda.
  final TenderAmounts spent;

  /// O vale do mês (RN-1006).
  final Money voucher;

  @override
  Widget build(BuildContext context) {
    return CajuiCard(
      sunken: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line(context, 'Gasto em dinheiro', spent.cash),
          const SizedBox(height: CajuiSpacing.sm),
          _line(context, 'Gasto no vale', spent.mealVoucher),
          const SizedBox(height: CajuiSpacing.lg),
          CajuiListRow(
            title: 'Vale do mês',
            subtitle: 'Só compra comida · muda em Minhas contas',
            trailing: CajuiAmountText(
              voucher.cents,
              tone: CajuiAmountTone.accent,
            ),
            semanticLabel: 'Vale do mês, mudar em Minhas contas',
            onPressed: () => MyBillsPage.open(context),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, Money amount) {
    final theme = CajuiTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.typography.body.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ),
        CajuiAmountText(amount.cents),
      ],
    );
  }
}
