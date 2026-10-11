import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Os fatos do plano da planilha no livro (ADR-023): todos os planos
/// definidos, para o histórico usar o de cada mês, e a ordem de quitação
/// das dívidas mais nova.
@immutable
final class BudgetFacts {
  /// Cria os fatos.
  const new({
    this.plans = const [],
    this.debtOrder = const [],
    this.orderedAt,
    this.debtVersions = const [],
  });

  /// Os planos, na ordem em que chegaram.
  final List<BudgetPlan> plans;

  /// A ordem de quitação, em identificadores de dívida.
  final List<String> debtOrder;

  /// Quando [debtOrder] foi decidida; nula sem ordem.
  final DateTime? orderedAt;

  /// Todas as versões das dívidas, na ordem em que chegaram: o mês a mês
  /// usa a que valia em cada mês, e negociar não reescreve o passado.
  final List<Debt> debtVersions;

  /// Com mais um plano definido.
  BudgetFacts defined(BudgetPlan plan) => BudgetFacts(
    plans: [...plans, plan],
    debtOrder: debtOrder,
    orderedAt: orderedAt,
    debtVersions: debtVersions,
  );

  /// Com mais uma versão de dívida.
  BudgetFacts withDebtVersion(Debt debt) => BudgetFacts(
    plans: plans,
    debtOrder: debtOrder,
    orderedAt: orderedAt,
    debtVersions: [...debtVersions, debt],
  );

  /// Com a ordem [ids], decidida em [at]. A ordem mais velha, chegando
  /// depois de outro aparelho, não passa por cima da mais nova.
  BudgetFacts ordered(List<String> ids, DateTime at) {
    final known = orderedAt;
    if (known != null && known.isAfter(at)) return this;
    return BudgetFacts(
      plans: plans,
      debtOrder: ids,
      orderedAt: at,
      debtVersions: debtVersions,
    );
  }
}
