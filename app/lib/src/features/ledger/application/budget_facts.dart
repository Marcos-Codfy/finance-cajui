import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Os fatos do plano da planilha no livro (ADR-023): todos os planos
/// definidos, para o histórico usar o de cada mês, a ordem de quitação
/// das dívidas mais nova e os nomes da casa (RN-1070).
@immutable
final class BudgetFacts {
  /// Cria os fatos.
  const new({
    this.plans = const [],
    this.debtOrder = const [],
    this.orderedAt,
    this.debtVersions = const [],
    this.household = HouseholdNames.empty,
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

  /// Os nomes de quem divide o orçamento, a lista mais nova (RN-1070).
  final HouseholdNames household;

  /// Com mais um plano definido.
  BudgetFacts defined(BudgetPlan plan) => _with(plans: [...plans, plan]);

  /// Com mais uma versão de dívida.
  BudgetFacts withDebtVersion(Debt debt) =>
      _with(debtVersions: [...debtVersions, debt]);

  /// Com a ordem [ids], decidida em [at]. A ordem mais velha, chegando
  /// depois de outro aparelho, não passa por cima da mais nova.
  BudgetFacts ordered(List<String> ids, DateTime at) {
    final known = orderedAt;
    if (known != null && known.isAfter(at)) return this;
    return _with(debtOrder: ids, orderedAt: at);
  }

  /// Com os nomes da casa [names]. A lista mais velha, chegando depois de
  /// outro aparelho, não passa por cima da mais nova (ADR-024).
  BudgetFacts named(HouseholdNames names) =>
      household.isNewerThan(names) ? this : _with(household: names);

  BudgetFacts _with({
    List<BudgetPlan>? plans,
    List<String>? debtOrder,
    DateTime? orderedAt,
    List<Debt>? debtVersions,
    HouseholdNames? household,
  }) => BudgetFacts(
    plans: plans ?? this.plans,
    debtOrder: debtOrder ?? this.debtOrder,
    orderedAt: orderedAt ?? this.orderedAt,
    debtVersions: debtVersions ?? this.debtVersions,
    household: household ?? this.household,
  );
}
