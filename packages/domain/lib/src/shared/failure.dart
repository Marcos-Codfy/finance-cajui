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
