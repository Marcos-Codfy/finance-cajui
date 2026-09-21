import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// O saldo do vale alimentação.
///
/// Saldo = saldo anterior + créditos − pagamentos em vale + estornos em vale
/// + ajustes (RN-120). Não há integração com a operadora: o saldo é o que o
/// Cajui calcula, e a pessoa o corrige quando o real for outro (RN-123).
///
/// O saldo **passa inteiro de um mês para o outro** (RN-121) — por isso a
/// conta não sabe de mês nenhum — e **nunca fica negativo** (RN-122).
@immutable
final class VoucherAccount {
  /// Cria a conta com o saldo [balance].
  new({this.balance = Money.zero})
    : assert(!balance.isNegative, 'O saldo do vale nunca é negativo.');

  /// O saldo disponível.
  final Money balance;

  /// O crédito do mês caiu.
  VoucherAccount credit(Money amount) =>
      VoucherAccount(balance: balance + amount);

  /// Paga [amount] no vale. Recusa se o saldo não cobre (RN-122): o app então
  /// oferece dividir o pagamento, com [coverableFor] no vale.
  Result<VoucherAccount> pay(Money amount) {
    if (amount > balance) {
      return Err(VoucherBalanceExceeded(balance: balance, requested: amount));
    }
    return Ok(VoucherAccount(balance: balance - amount));
  }

  /// Um pagamento em vale foi estornado: o valor volta ao saldo.
  VoucherAccount reverse(Money amount) =>
      VoucherAccount(balance: balance + amount);

  /// Quanto de uma compra de [purchase] o vale consegue cobrir.
  ///
  /// Saldo de R$ 30 e compra de R$ 86: R$ 30 no vale, e o resto de outro
  /// jeito.
  Money coverableFor(Money purchase) =>
      purchase <= balance ? purchase : balance;

  /// A diferença entre o saldo real, informado pela pessoa, e o calculado.
  ///
  /// É o valor do evento de **ajuste** (RN-123): não é renda nem despesa e
  /// não entra em indicador nenhum. Saldo calculado de R$ 170,00 e real de
  /// R$ 162,10 dão um ajuste de −R$ 7,90.
  Money adjustmentTo(Money actualBalance) => actualBalance - balance;

  /// Aplica um ajuste de saldo já calculado por [adjustmentTo].
  VoucherAccount adjust(Money adjustment) =>
      VoucherAccount(balance: balance + adjustment);

  @override
  bool operator ==(Object other) =>
      other is VoucherAccount && other.balance == balance;

  @override
  int get hashCode => balance.hashCode;
}
