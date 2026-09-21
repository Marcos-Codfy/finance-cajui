import 'package:domain/src/budget/month_plan.dart';
import 'package:domain/src/budget/planned_variable.dart';
import 'package:domain/src/indicators/month_spending.dart';
import 'package:domain/src/indicators/percent.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender_amounts.dart';
import 'package:meta/meta.dart';

/// Os indicadores de um mês: função pura do plano e do que foi gasto.
///
/// Os mesmos eventos produzem os mesmos números, no aparelho e no servidor
/// (RN-601) — e **a IA nunca calcula nenhum deles** (RN-602): o assistente
/// diz "sobram R$ 558,00" porque recebeu o número pronto daqui.
@immutable
final class MonthIndicators {
  /// Calcula os indicadores de [plan] com o gasto [spending] do mês.
  const new(this.plan, this.spending);

  /// O plano do mês.
  final MonthPlan plan;

  /// O gasto variável em dinheiro do mês.
  final MonthSpending spending;

  Money get _committed => plan.fixedTotal + plan.debtInstallments;

  /// O **resultado planejado**, em dinheiro: `P = RC − F − D − Vd` (RN-620).
  /// Positivo é sobra; negativo, falta; zero, "o mês fecha no zero" (RN-622).
  Money get plannedResult =>
      plan.cashIncome - _committed - plan.variableCash;

  /// O **resultado projetado** (RN-621): o planejado, com o real onde ele já
  /// é conhecido. Em cada variável entra o maior entre o gasto e o máximo; o
  /// gasto em categoria sem faixa entra inteiro (RN-424); o fora do padrão
  /// também (RN-648).
  Money get projectedResult =>
      plan.cashIncome - _committed - _projectedVariable - spending.exceptional;

  Money get _projectedVariable {
    final planned = {for (final v in plan.variables) v.budget.categoryId: v};
    var total = plan.variableCash;
    for (final MapEntry(key: category, value: spent)
        in spending.routineByCategory.entries) {
      final line = planned[category];
      final over = spent - (line?.cashAtMax ?? Money.zero);
      if (over.isPositive) total += over;
    }
    return total;
  }

  /// O **comprometimento total** da renda: `(F + D) ÷ RC`, em percentual
  /// inteiro (RN-630). Nulo quando não há renda em dinheiro (RN-604).
  int? get commitmentPercent => percentOfIncome(_committed);

  /// Quanto [amount] representa da renda em dinheiro — a conta do
  /// comprometimento por grupo: moradia, transporte, assinaturas (RN-631).
  int? percentOfIncome(Money amount) => Percent.of(amount, plan.cashIncome);

  /// O **custo de vida por dia** planejado, por moeda (RN-650). Em dinheiro:
  /// `(F + D + Vd) ÷ dias do mês`. Em vale: o que o vale cobre do pior caso,
  /// dividido pelos dias. É média do período, nunca o gasto de hoje (RN-652).
  TenderAmounts get plannedDailyCost {
    final days = plan.month.length;
    final voucher = plan.variables.fold(
      Money.zero,
      (sum, line) => sum + line.voucherAtMax,
    );
    return TenderAmounts(
      cash: Money.ratio(_committed + plan.variableCash, 1, days),
      mealVoucher: Money.ratio(voucher, 1, days),
    );
  }

  /// O **ajuste necessário**: `A = máx(0, −resultado projetado)` (RN-660).
  Money get requiredAdjustment => (-projectedResult).orZeroIfNegative;

  /// A **folga ajustável**: quanto de dinheiro ainda dá para economizar nos
  /// variáveis — `máx(0, máximo − máx(gasto, mínimo))`, na parte em dinheiro
  /// (RN-661).
  Money get adjustableSlack => plan.variables.fold(
    Money.zero,
    (sum, line) => sum + slackOf(line),
  );

  /// A folga que resta em [line], dado o que já foi gasto nela.
  Money slackOf(PlannedVariable line) {
    final spent =
        spending.routineByCategory[line.budget.categoryId] ?? Money.zero;
    final floor = spent > line.cashAtMin ? spent : line.cashAtMin;
    return (line.cashAtMax - floor).orZeroIfNegative;
  }

  /// O mês fecha só ajustando variáveis: `A ≤ S` (RN-662). Quando não fecha,
  /// o app diz com clareza que os variáveis cobrem só `S`, e que o resto
  /// depende de renda, de fixo ou de dívida.
  bool get closesByAdjustingVariables => requiredAdjustment <= adjustableSlack;

  /// Os variáveis em que dá para cortar, do maior corte possível para o
  /// menor. Nada é aplicado sozinho: aceitar uma sugestão é ação explícita de
  /// quem usa (RN-663).
  List<PlannedVariable> get adjustmentOptions =>
      plan.variables.where((line) => slackOf(line).isPositive).toList()
        ..sort((a, b) => slackOf(b).compareTo(slackOf(a)));
}
