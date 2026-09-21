import 'package:domain/src/budget/planned_variable.dart';
import 'package:domain/src/calendar/calendar_words.dart';
import 'package:domain/src/indicators/month_indicators.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/money_format.dart';
import 'package:domain/src/money/tender_amounts.dart';
import 'package:meta/meta.dart';

/// O resumo do mês (RN-831 a RN-837), pelo modelo de frase (RN-802).
///
/// Tem sempre as duas partes, nesta ordem: **como foi o mês** — que começa
/// pelo que foi cumprido, mesmo em mês com falta (RN-832, RN-837) — e **como
/// fica adiante**, com até três sugestões, cada uma com valor. A falta é
/// valor a recompor, nunca bronca, e nada é aplicado sozinho (RN-663).
@immutable
final class MonthlySummary {
  /// O resumo do mês de [indicators]. [spent] é o gasto por moeda,
  /// [voucherBalance] o saldo do vale, e [categoryName] dá o nome de uma
  /// categoria para as sugestões.
  const new({
    required this.indicators,
    required this.spent,
    required this.voucherBalance,
    required this.categoryName,
  });

  /// Os indicadores do mês.
  final MonthIndicators indicators;

  /// O gasto do mês, por moeda — nunca somado (RN-804).
  final TenderAmounts spent;

  /// O saldo do vale.
  final Money voucherBalance;

  /// O nome da categoria de identificador dado.
  final String Function(String categoryId) categoryName;

  /// No máximo três sugestões (RN-835).
  static const _maxSuggestions = 3;

  String get _month => CalendarWords.month(indicators.plan.month);

  /// "Como foi o mês", começando pelo que foi cumprido.
  List<String> get howItWent => [_withinRange, _result, _blocks, _voucher];

  /// O vale tem linha própria: não entra em nenhuma soma (RN-804).
  String get _voucher =>
      'Vale: ${MoneyFormat.brl(spent.mealVoucher)} gastos, '
      '${MoneyFormat.brl(voucherBalance)} de saldo.';

  /// "Como fica adiante": as sugestões, do maior ajuste possível ao menor.
  List<String> get whatComesNext {
    final missing = indicators.requiredAdjustment;
    if (missing.isZero) {
      return ['Nada a recompor: o plano de $_month está coberto.'];
    }
    final options = indicators.adjustmentOptions.take(_maxSuggestions);
    return [
      for (final line in options) _suggestion(line),
      if (!indicators.closesByAdjustingVariables)
        'Os variáveis sozinhos não cobrem: vale rever um fixo.',
    ];
  }

  String _suggestion(PlannedVariable line) =>
      'Ajustar ${categoryName(line.budget.categoryId)} em até '
      '${MoneyFormat.brl(indicators.slackOf(line))}.';

  String get _withinRange {
    final lines = indicators.plan.variables;
    final within = lines.where((line) {
      final used = indicators.spending.routineByCategory;
      return (used[line.budget.categoryId] ?? Money.zero) <= line.cashAtMax;
    }).length;
    return lines.isEmpty
        ? 'Ainda sem faixas de gastos variáveis no plano.'
        : '$within de ${lines.length} variáveis dentro do previsto.';
  }

  /// O resultado, comparado ao plano (RN-833). É projeção enquanto o mês
  /// anda, e a frase diz isso.
  String get _result {
    if (!indicators.plan.cashIncome.isPositive) {
      return 'Sem renda cadastrada, não dá para dizer como $_month fecha.';
    }
    final missing = indicators.requiredAdjustment;
    if (missing.isPositive) {
      return 'Pelo que está lançado, faltam ${MoneyFormat.brl(missing)} para '
          'fechar $_month.';
    }
    final projected = indicators.projectedResult;
    final gap = projected - indicators.plannedResult;
    final versusPlan = gap.isZero
        ? 'como no plano'
        : '${MoneyFormat.brl(gap.isNegative ? -gap : gap)} '
              '${gap.isNegative ? 'abaixo' : 'acima'} do plano';
    return 'Pelo que está lançado, $_month fecha com '
        '${MoneyFormat.brl(projected)} de sobra, $versusPlan.';
  }

  String get _blocks {
    final plan = indicators.plan;
    // Só o variável de rotina, em dinheiro: é o que o plano compara.
    final variable = indicators.spending.routineByCategory.values.fold(
      Money.zero,
      (sum, amount) => sum + amount,
    );
    return 'Fixos ${MoneyFormat.brl(plan.fixedTotal)} · variáveis '
        '${MoneyFormat.brl(variable)} em dinheiro · dívidas '
        '${MoneyFormat.brl(plan.debtInstallments)}.';
  }
}
