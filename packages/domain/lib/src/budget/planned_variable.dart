import 'package:domain/src/budget/variable_budget.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Um variável já dentro do plano de um mês, com a parte que o vale cobre
/// separada da parte que sai em dinheiro.
@immutable
final class PlannedVariable {
  /// Cria a linha do plano.
  const new({
    required this.budget,
    required this.cashAtMax,
    required this.cashAtMin,
  });

  /// Distribui o [voucher] disponível entre os variáveis elegíveis, **na
  /// ordem do plano**, até acabar (RN-426). O que o vale não cobre sai em
  /// dinheiro: `máx(0, máximo − vale disponível)` (RN-425).
  ///
  /// A conta é feita duas vezes — pelo máximo e pelo mínimo de cada faixa —,
  /// porque a diferença entre as duas é quanto de **dinheiro** dá para
  /// economizar naquela categoria.
  static List<PlannedVariable> allocate(
    List<VariableBudget> budgets,
    Money voucher,
  ) {
    var leftAtMax = voucher;
    var leftAtMin = voucher;
    final planned = <PlannedVariable>[];
    for (final budget in budgets) {
      final coveredAtMax = _covered(budget, budget.range.max, leftAtMax);
      final coveredAtMin = _covered(budget, budget.range.min, leftAtMin);
      leftAtMax -= coveredAtMax;
      leftAtMin -= coveredAtMin;
      planned.add(
        PlannedVariable(
          budget: budget,
          cashAtMax: budget.range.max - coveredAtMax,
          cashAtMin: budget.range.min - coveredAtMin,
        ),
      );
    }
    return planned;
  }

  static Money _covered(VariableBudget budget, Money amount, Money voucher) {
    if (!budget.voucherEligible) return Money.zero;
    return amount <= voucher ? amount : voucher;
  }

  /// O variável planejado.
  final VariableBudget budget;

  /// A parte em dinheiro do pior caso: é ela que entra no plano.
  final Money cashAtMax;

  /// A parte em dinheiro gastando só o mínimo da faixa.
  final Money cashAtMin;

  /// A parte do pior caso que o vale cobre.
  Money get voucherAtMax => budget.range.max - cashAtMax;

  /// Quanto de **dinheiro** dá para economizar aqui num mês apertado.
  ///
  /// Mercado de R$ 500–800 com R$ 650 de vale: no máximo saem R$ 150 em
  /// dinheiro; no mínimo, nada. A folga é R$ 150, e não os R$ 300 da faixa.
  Money get cashSlack => cashAtMax - cashAtMin;
}
