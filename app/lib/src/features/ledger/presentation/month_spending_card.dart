import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O que já foi gasto no mês, **uma linha por moeda**, num cartão baixo: a
/// lista de lançamentos é o assunto da tela e precisa aparecer logo
/// (27/11/2026).
///
/// Não há linha de total: dinheiro e vale alimentação não se somam em lugar
/// nenhum do Cajui (RN-111). Quem vê "R$ 640" quer saber de qual bolso saiu.
/// O "O que é cada número?" explica por que este número não é o "Gastos" do
/// Painel: aqui é o já lançado; lá, o previsto do mês inteiro.
class MonthSpendingCard extends StatelessWidget {
  /// Cria o cartão com o gasto [spent].
  const new({required this.spent, super.key});

  /// O gasto do mês, por moeda.
  final TenderAmounts spent;

  /// A explicação curta, no tom do guia de voz.
  static const String explanation =
      'Aqui está o que já foi lançado neste mês. No Painel, "Gastos do mês" '
      'é o previsto para o mês todo: conta as contas que ainda vão vencer e '
      'o que a planilha reserva para o dia a dia. O vale alimentação é '
      'outra moeda e nunca se soma ao dinheiro.';

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiCard(
      sunken: true,
      padding: const EdgeInsets.symmetric(
        horizontal: CajuiSpacing.lg,
        vertical: CajuiSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line(theme, 'Já gasto em dinheiro', spent.cash),
          const SizedBox(height: CajuiSpacing.xs),
          _line(theme, 'Já gasto no vale alimentação', spent.mealVoucher),
          CajuiDisclosure(
            title: 'O que é cada número?',
            children: [
              Text(
                explanation,
                style: theme.typography.caption.copyWith(
                  color: theme.colors.text.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(CajuiThemeData theme, String label, Money amount) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
      ),
      CajuiAmountText(amount.cents),
    ],
  );
}
