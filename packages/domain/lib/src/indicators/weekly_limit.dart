import 'package:domain/src/indicators/budget_week.dart';
import 'package:domain/src/indicators/month_spending.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O **limite da semana**: o número que o painel mostra primeiro (RN-670),
/// porque continua útil mesmo com o mês no negativo.
///
/// `limite = ⌊ restante × dias da semana no mês ÷ dias restantes no mês ⌋`
/// (RN-641). O restante é o orçamento variável menos o que já foi gasto
/// **antes** do início da semana (RN-646) — então a semana que passou do
/// limite dilui o excesso nas seguintes, e a semana boa aumenta o das
/// próximas. Ninguém leva bronca; a conta só se refaz.
///
/// É informação, não bloqueio: nenhum lançamento é recusado por passar do
/// limite (RN-647).
@immutable
final class WeeklyLimit {
  /// Calcula o limite de [week], com o orçamento variável em dinheiro do mês
  /// em [variableBudget] (`VB`, RN-640) e o gasto de rotina em [spending].
  factory of({
    required BudgetWeek week,
    required Money variableBudget,
    required MonthSpending spending,
  }) {
    final remaining = variableBudget - spending.routineBefore(week.start);
    return WeeklyLimit._(
      week: week,
      remainingBudget: remaining,
      spent: spending.routineBetween(week.start, week.end),
      // Limite de gasto arredonda para baixo (RN-103); sem restante, é zero
      // (RN-645).
      limit: remaining.isPositive
          ? Money.ratioFloor(remaining, week.days, week.daysLeftInMonth)
          : Money.zero,
    );
  }

  const new _({
    required this.week,
    required this.remainingBudget,
    required this.limit,
    required this.spent,
  });

  /// O limite que esta semana teria se a anterior **não** tivesse passado do
  /// dela em [previousOverrun]. É o "seria" do resumo semanal: "o limite
  /// ficou R$ 9,78 menor do que seria" (RN-822).
  Money limitWithout(Money previousOverrun) {
    final restored = remainingBudget + previousOverrun;
    if (!restored.isPositive) return Money.zero;
    return Money.ratioFloor(restored, week.days, week.daysLeftInMonth);
  }

  /// A semana a que o limite se refere.
  final BudgetWeek week;

  /// O que restava do variável do mês no início da semana. Pode ser
  /// negativo.
  final Money remainingBudget;

  /// O limite da semana.
  final Money limit;

  /// O gasto de rotina já feito na semana.
  final Money spent;

  /// O **resta na semana** (RN-642). Negativo significa "a semana passou
  /// R$ X do limite" — dito assim, sem alarme.
  Money get remaining => limit - spent;

  /// Quanto o variável do mês já passou do plano, quando passou (RN-645):
  /// "o variável do mês já passou R$ 40,00 do plano".
  Money get monthOverrun => (-remainingBudget).orZeroIfNegative;
}
