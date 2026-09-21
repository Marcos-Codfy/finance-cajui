import 'package:cajui/src/features/ledger/presentation/voucher_balance_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O gasto do mês, **uma linha por moeda**, e o saldo do vale.
///
/// Não há linha de total: dinheiro e vale não se somam em lugar nenhum do
/// Cajui (RN-111). Quem vê "R$ 640" quer saber de qual bolso saiu.
class MonthSpendingCard extends StatelessWidget {
  /// Cria o cartão com o gasto [spent] e a conta do vale [voucher].
  const new({required this.spent, required this.voucher, super.key});

  /// O gasto do mês, por moeda.
  final TenderAmounts spent;

  /// A conta do vale.
  final VoucherAccount voucher;

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
            title: 'Saldo do vale',
            subtitle: 'Toque para corrigir pelo saldo da operadora',
            trailing: CajuiAmountText(
              voucher.balance.cents,
              tone: CajuiAmountTone.accent,
            ),
            semanticLabel: 'Saldo do vale, corrigir',
            onPressed: () => VoucherBalancePage.open(context),
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
