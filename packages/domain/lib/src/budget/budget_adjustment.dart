import 'package:domain/src/budget/variable_budget.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';

/// Um corte no pior caso de um variável, para fechar um mês apertado.
///
/// Nada é ajustado sozinho: o app lista o que dá para cortar, e aceitar uma
/// sugestão é uma ação explícita e registrada de quem usa (RN-663).
abstract final class BudgetAdjustment {
  /// O novo máximo de [budget] depois de cortar [cut], ou a recusa, se o
  /// corte deixaria a categoria abaixo do mínimo da faixa (`E-BUDG-03`) — o
  /// mínimo é o que a pessoa disse que não dá para cortar.
  static Result<Money> maxAfterCut(VariableBudget budget, Money cut) {
    if (!cut.isPositive) return Err(NonPositiveAmount(cut));
    final result = budget.range.max - cut;
    if (result < budget.range.min) {
      return Err(
        AdjustmentBelowMinimum(
          categoryId: budget.categoryId,
          minimum: budget.range.min,
          result: result,
        ),
      );
    }
    return Ok(result);
  }
}
