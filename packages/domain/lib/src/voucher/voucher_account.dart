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
///
/// Por dentro a conta guarda a soma **com sinal**. É o que faz ela dar o
/// mesmo resultado em qualquer ordem de chegada dos fatos: dois celulares
/// recebem os mesmos fatos em ordens diferentes, e parar em zero no meio do
/// caminho faria cada um chegar a um saldo (RN-124).
@immutable
final class VoucherAccount {
  /// Cria a conta com o saldo [balance].
  new({Money balance = Money.zero})
    : assert(!balance.isNegative, 'O saldo do vale nunca é negativo.'),
      _net = balance;

  const new _(this._net);

  /// O que os fatos somam, com sinal.
  final Money _net;

  /// O saldo disponível.
  Money get balance => _net.orZeroIfNegative;

  /// Quanto os pagamentos já registrados **passam** do saldo; zero no caso
  /// comum (RN-124).
  ///
  /// Só acontece com fato que não dava para recusar: dois aparelhos que
  /// gastaram o mesmo saldo sem rede, ou um registro antigo. O próximo
  /// crédito, estorno ou ajuste cobre primeiro esta diferença.
  Money get overdrawn => _net.isNegative ? -_net : Money.zero;

  /// O crédito do mês caiu.
  VoucherAccount credit(Money amount) => VoucherAccount._(_net + amount);

  /// Paga [amount] no vale. Recusa se o saldo não cobre (RN-122): o app então
  /// oferece dividir o pagamento, com [coverableFor] no vale.
  Result<VoucherAccount> pay(Money amount) {
    if (amount > balance) {
      return Err(VoucherBalanceExceeded(balance: balance, requested: amount));
    }
    return Ok(VoucherAccount._(_net - amount));
  }

  /// Desconta um pagamento que **já aconteceu**: relido do registro, ou
  /// vindo de outro aparelho. Não recusa — fato não se recusa depois —, e o
  /// que passar do saldo fica em [overdrawn] (RN-124).
  VoucherAccount settle(Money amount) => VoucherAccount._(_net - amount);

  /// Um pagamento em vale foi estornado: o valor volta ao saldo.
  VoucherAccount reverse(Money amount) => VoucherAccount._(_net + amount);

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
  /// R$ 162,10 dão um ajuste de −R$ 7,90. Com a conta a descoberto, o ajuste
  /// cobre também o descoberto: o saldo informado é o que passa a valer.
  Money adjustmentTo(Money actualBalance) => actualBalance - _net;

  /// Aplica um ajuste de saldo já calculado por [adjustmentTo].
  VoucherAccount adjust(Money adjustment) =>
      VoucherAccount._(_net + adjustment);

  @override
  bool operator ==(Object other) =>
      other is VoucherAccount && other._net == _net;

  @override
  int get hashCode => _net.hashCode;
}
