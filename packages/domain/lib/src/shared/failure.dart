import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';

/// Uma recusa do domínio: a regra que não deixou a operação acontecer, com os
/// dados que o texto do erro vai usar.
///
/// A hierarquia é selada: um `switch` sobre `Failure` é exaustivo, e uma
/// falha nova sem tratamento — sem código no catálogo, sem texto na tela —
/// **não compila** (ADR-015). Cada caso corresponde a uma linha de
/// `docs/spec/error-catalog.md`.
///
/// Só moram aqui as falhas de regra de negócio. Falha de rede, de leitura de
/// comprovante ou de autenticação nasce nas camadas de fora, em hierarquias
/// próprias.
sealed class Failure {
  const new();
}

/// `E-ENTRY-01` · A soma das linhas de pagamento difere do valor (RN-203).
final class PaymentLinesMismatch extends Failure {
  /// Cria a falha com o valor do lançamento e a soma das linhas.
  const new({required this.amount, required this.linesTotal});

  /// O valor do lançamento.
  final Money amount;

  /// A soma das linhas de pagamento informadas.
  final Money linesTotal;

  /// Quanto falta (positivo) ou sobra (negativo) para fechar a conta.
  Money get difference => amount - linesTotal;
}

/// `E-ENTRY-02` · A data da compra está no futuro (RN-206).
final class PurchaseDateInFuture extends Failure {
  /// Cria a falha com a data informada e o dia de hoje.
  const new({required this.occurredOn, required this.today});

  /// A data que se tentou lançar.
  final LocalDate occurredOn;

  /// O dia de hoje, no fuso de negócio.
  final LocalDate today;
}

/// `E-ENTRY-03` · Valor zero ou negativo (RN-104).
final class NonPositiveAmount extends Failure {
  /// Cria a falha com o valor recusado.
  const new(this.amount);

  /// O valor que se tentou usar.
  final Money amount;
}

/// `E-ENTRY-04` · O estorno passa do que resta estornar (RN-210).
final class ReversalExceedsRemaining extends Failure {
  /// Cria a falha com o que resta e o que foi pedido.
  const new({required this.remaining, required this.requested});

  /// Quanto ainda pode ser estornado naquela forma de pagamento.
  final Money remaining;

  /// O valor do estorno pedido.
  final Money requested;
}

/// `E-CARD-01` · Dia de fechamento ou de vencimento fora de 1 a 31.
final class InvalidCardDay extends Failure {
  /// Cria a falha com o dia recusado.
  const new(this.day);

  /// O dia que se tentou usar.
  final int day;
}

/// `E-CARD-02` · O nome da categoria representa um cartão ou uma fatura
/// (RN-207 e RN-301).
final class CategoryRepresentsCard extends Failure {
  /// Cria a falha com o nome recusado, para o texto do erro.
  const new(this.name);

  /// O nome que se tentou dar à categoria.
  final String name;
}

/// `E-VOUCHER-02` · A categoria não pode ser paga com vale (RN-112).
final class CategoryNotVoucherEligible extends Failure {
  /// Cria a falha com o nome da categoria, para o texto do erro.
  const new(this.categoryName);

  /// O nome da categoria recusada.
  final String categoryName;
}

/// `E-VOUCHER-01` · O pagamento no vale é maior que o saldo (RN-122).
final class VoucherBalanceExceeded extends Failure {
  /// Cria a falha com o saldo disponível e o valor pedido.
  const new({required this.balance, required this.requested});

  /// O saldo do vale no momento do pagamento.
  final Money balance;

  /// O valor que se tentou pagar no vale.
  final Money requested;

  /// Quanto falta cobrir de outro jeito: é o que o app propõe pagar em
  /// dinheiro ao oferecer a divisão do pagamento.
  Money get uncovered => requested - balance;
}
