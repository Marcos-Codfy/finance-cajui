import 'package:cajui/src/features/insights/application/insights.dart';

/// Os três períodos de resumo, na ordem do mais frequente para o mais raro.
enum InsightPeriod {
  /// Hoje.
  day('Hoje'),

  /// A semana em curso.
  week('Semana'),

  /// O mês em curso.
  month('Mês');

  new(this.label);

  /// O nome do período no seletor.
  final String label;

  static const _noWeeklyLimitYet =
      'O resumo da semana aparece quando os gastos variáveis tiverem faixa '
      'no plano: é delas que sai o limite da semana.';

  /// As seções do resumo deste período: título, quando há, e frases.
  List<(String?, List<String>)> sections(Insights insights) => switch (this) {
    InsightPeriod.day => [(null, insights.daily.lines)],
    InsightPeriod.week => [
      (null, insights.weekly?.lines ?? const [_noWeeklyLimitYet]),
    ],
    // As duas partes do mês, sempre nesta ordem (RN-831).
    InsightPeriod.month => [
      ('Como foi o mês', insights.monthly.howItWent),
      ('Como fica adiante', insights.monthly.whatComesNext),
    ],
  };
}
