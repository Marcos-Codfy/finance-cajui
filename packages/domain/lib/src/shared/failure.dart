import 'package:domain/src/calendar/budget_month.dart';
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
///
/// As falhas se agrupam por área, em famílias também seladas. Quem traduz
/// falha em código de erro faz um `switch` por família: cada um é curto, e
/// todos continuam exaustivos.
sealed class Failure {
  const new();
}

/// As recusas de lançamento e de estorno.
sealed class EntryFailure extends Failure {
  const new();
}

/// As recusas do vale alimentação.
sealed class VoucherFailure extends Failure {
  const new();
}

/// As recusas de cartão de crédito.
sealed class CardFailure extends Failure {
  const new();
}

/// As recusas do plano do mês.
sealed class BudgetFailure extends Failure {
  const new();
}

/// As recusas de dívida.
sealed class DebtFailure extends Failure {
  const new();
}

/// `E-DEBT-01` · Mais parcelas pagas do que o total de parcelas (RN-501).
final class PaidInstallmentsExceedTotal extends DebtFailure {
  /// Cria a falha com o total e o número de pagas informados.
  const new({required this.total, required this.paid});

  /// O total de parcelas da dívida.
  final int total;

  /// Quantas parcelas foram informadas como pagas.
  final int paid;
}

/// `E-ENTRY-01` · A soma das linhas de pagamento difere do valor (RN-203).
final class PaymentLinesMismatch extends EntryFailure {
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
final class PurchaseDateInFuture extends EntryFailure {
  /// Cria a falha com a data informada e o dia de hoje.
  const new({required this.occurredOn, required this.today});

  /// A data que se tentou lançar.
  final LocalDate occurredOn;

  /// O dia de hoje, no fuso de negócio.
  final LocalDate today;
}

/// `E-ENTRY-03` · Valor zero ou negativo (RN-104).
final class NonPositiveAmount extends EntryFailure {
  /// Cria a falha com o valor recusado.
  const new(this.amount);

  /// O valor que se tentou usar.
  final Money amount;
}

/// `E-ENTRY-04` · O estorno passa do que resta estornar (RN-210).
final class ReversalExceedsRemaining extends EntryFailure {
  /// Cria a falha com o que resta e o que foi pedido.
  const new({required this.remaining, required this.requested});

  /// Quanto ainda pode ser estornado naquela forma de pagamento.
  final Money remaining;

  /// O valor do estorno pedido.
  final Money requested;
}

/// `E-REQ-02` · O lançamento a corrigir não existe mais: foi cancelado em
/// outro aparelho enquanto a correção estava aberta (BL-062).
final class EntryNoLongerExists extends EntryFailure {
  /// Cria a falha para o lançamento [entryId].
  const new(this.entryId);

  /// O lançamento que não existe mais.
  final String entryId;
}

/// `E-BUDG-01` · Faixa com mínimo maior que o máximo, ou negativa (RN-420).
final class RangeMinAboveMax extends BudgetFailure {
  /// Cria a falha com os dois limites informados.
  const new({required this.min, required this.max});

  /// O mínimo informado.
  final Money min;

  /// O máximo informado.
  final Money max;
}

/// `E-BUDG-02` · Tentativa de fechar um mês que ainda não terminou (RN-442).
final class MonthNotOver extends BudgetFailure {
  /// Cria a falha com o mês e o primeiro dia em que ele pode ser fechado.
  const new({required this.month, required this.closableFrom});

  /// O mês que se tentou fechar.
  final BudgetMonth month;

  /// O primeiro dia em que o fechamento passa a ser aceito.
  final LocalDate closableFrom;
}

/// `E-BUDG-03` · O ajuste deixaria a categoria abaixo do mínimo da faixa.
final class AdjustmentBelowMinimum extends BudgetFailure {
  /// Cria a falha com a categoria, o mínimo dela e onde o ajuste a deixaria.
  const new({
    required this.categoryId,
    required this.minimum,
    required this.result,
  });

  /// A categoria que se tentou ajustar.
  final String categoryId;

  /// O mínimo da faixa: o que a pessoa disse que não dá para cortar.
  final Money minimum;

  /// O valor em que a categoria ficaria depois do ajuste.
  final Money result;
}

/// `E-BUDG-04` · Remanejamento maior que a folga da origem (RN-403).
final class ReallocationExceedsSlack extends BudgetFailure {
  /// Cria a falha com a folga da origem e o valor pedido.
  const new({required this.slack, required this.requested});

  /// Quanto a categoria de origem ainda tem de folga.
  final Money slack;

  /// Quanto se tentou mover.
  final Money requested;
}

/// `E-CARD-01` · Dia de fechamento ou de vencimento fora de 1 a 31.
final class InvalidCardDay extends CardFailure {
  /// Cria a falha com o dia recusado.
  const new(this.day);

  /// O dia que se tentou usar.
  final int day;
}

/// `E-CARD-02` · O nome da categoria representa um cartão ou uma fatura
/// (RN-207 e RN-301).
final class CategoryRepresentsCard extends CardFailure {
  /// Cria a falha com o nome recusado, para o texto do erro.
  const new(this.name);

  /// O nome que se tentou dar à categoria.
  final String name;
}

/// `E-VOUCHER-02` · A categoria não pode ser paga com vale (RN-112).
final class CategoryNotVoucherEligible extends VoucherFailure {
  /// Cria a falha com o nome da categoria, para o texto do erro.
  const new(this.categoryName);

  /// O nome da categoria recusada.
  final String categoryName;
}

/// `E-VOUCHER-01` · O pagamento no vale é maior que o saldo (RN-122).
final class VoucherBalanceExceeded extends VoucherFailure {
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
