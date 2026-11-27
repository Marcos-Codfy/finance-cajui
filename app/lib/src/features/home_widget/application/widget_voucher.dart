import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:domain/domain.dart';

/// O número do widget do vale alimentação: o rótulo e o valor, já em texto.
typedef WidgetVoucherWords = ({String label, String amount});

/// O que o widget do vale mostra. O vale é outra moeda e nunca se soma ao
/// dinheiro (RN-111): por isso tem widget próprio, e não uma linha no do
/// mês.
///
/// É a mesma escolha do Início: o saldo, quando há crédito registrado; sem
/// ele, o vale do mês do plano — "Saldo de R$ 0,00" ao lado de um vale de
/// R$ 500 no plano confundiria.
abstract final class WidgetVoucher {
  /// As palavras de [view], ou `null` para quem não tem vale.
  static WidgetVoucherWords? of(HomeView view) {
    final balance = view.voucherBalance;
    final planned = view.budget.voucher;
    if (balance.isPositive) {
      return (label: 'Saldo do vale', amount: MoneyFormat.brl(balance));
    }
    if (planned.isPositive) {
      return (
        label: 'Vale alimentação do mês',
        amount: MoneyFormat.brl(planned),
      );
    }
    return null;
  }
}
