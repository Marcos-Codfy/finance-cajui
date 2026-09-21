import 'package:domain/src/budget/fixed_expense.dart';
import 'package:domain/src/budget/fixed_occurrence.dart';
import 'package:domain/src/budget/planned_variable.dart';
import 'package:domain/src/budget/variable_budget.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O plano de um mês (RN-430): a renda em dinheiro, o vale disponível, os
/// fixos, os variáveis **pelo pior caso** e as parcelas de dívida do mês.
///
/// É uma visão derivada: na virada do mês nasce do que está vigente (RN-431),
/// e nunca é gravada como fato. Os três blocos ficam separados — nenhuma tela
/// usa um "gasto total" como número principal (RN-402).
@immutable
final class MonthPlan {
  /// Monta o plano de [month] a partir do que está vigente nele.
  ///
  /// [paidFixed] leva, por identificador do fixo, o valor do lançamento já
  /// ligado à ocorrência do mês (RN-411).
  factory of({
    required BudgetMonth month,
    required Money cashIncome,
    required Money voucherAvailable,
    required Iterable<FixedExpense> fixedExpenses,
    required Iterable<VariableBudget> variableBudgets,
    required Money debtInstallments,
    Map<String, Money> paidFixed = const {},
  }) {
    final active = variableBudgets
        .where((budget) => budget.validity.contains(month))
        .toList();
    return MonthPlan._(
      month: month,
      cashIncome: cashIncome,
      voucherAvailable: voucherAvailable,
      debtInstallments: debtInstallments,
      variables: List.unmodifiable(
        PlannedVariable.allocate(active, voucherAvailable),
      ),
      fixed: List.unmodifiable(_occurrences(month, fixedExpenses, paidFixed)),
    );
  }

  static Iterable<FixedOccurrence> _occurrences(
    BudgetMonth month,
    Iterable<FixedExpense> expenses,
    Map<String, Money> paid,
  ) => expenses
      .where((expense) => expense.validity.contains(month))
      .map(
        (expense) => FixedOccurrence(
          expense: expense,
          month: month,
          paidAmount: paid[expense.id],
        ),
      );

  const new _({
    required this.month,
    required this.cashIncome,
    required this.voucherAvailable,
    required this.fixed,
    required this.variables,
    required this.debtInstallments,
  });

  /// O mês planejado.
  final BudgetMonth month;

  /// A renda em dinheiro do mês — `RC` nas fórmulas.
  final Money cashIncome;

  /// O vale disponível: saldo que veio do mês anterior mais o crédito do mês
  /// — `VA`.
  final Money voucherAvailable;

  /// As ocorrências dos fixos vigentes.
  final List<FixedOccurrence> fixed;

  /// Os variáveis vigentes, na ordem do plano, já com o vale distribuído.
  final List<PlannedVariable> variables;

  /// As parcelas de dívida que vencem no mês — `D`.
  final Money debtInstallments;

  /// O total dos fixos — `F`.
  Money get fixedTotal =>
      fixed.fold(Money.zero, (sum, item) => sum + item.amount);

  /// O pior caso dos variáveis, só a parte em dinheiro — `Vd`.
  Money get variableCash =>
      variables.fold(Money.zero, (sum, item) => sum + item.cashAtMax);

  /// Quanto de dinheiro dá para economizar nos variáveis, ao todo.
  Money get adjustableSlack =>
      variables.fold(Money.zero, (sum, item) => sum + item.cashSlack);
}
