import 'package:domain/src/budget/fixed_occurrence.dart';
import 'package:domain/src/budget/month_plan.dart';
import 'package:domain/src/calendar/calendar_words.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/indicators/month_spending.dart';
import 'package:domain/src/indicators/weekly_limit.dart';
import 'package:domain/src/money/money_format.dart';
import 'package:meta/meta.dart';

/// O resumo da semana (RN-820 a RN-824), pelo modelo de frase (RN-802).
///
/// Semana que passou do limite é dita como fato, seguida do que já foi feito
/// com isso — o excesso se dilui nas seguintes (RN-805, RN-822). Não há
/// sequência punitiva nem bronca: a conta só se refaz.
@immutable
final class WeeklySummary {
  /// O resumo da semana de [today], com o plano [plan] e o gasto [spending].
  factory of({
    required LocalDate today,
    required MonthPlan plan,
    required MonthSpending spending,
    required WeeklyLimit week,
  }) {
    final nextWeek = week.week.next;
    return WeeklySummary._(
      today: today,
      week: week,
      quietDays: _quietDays(week, spending, today),
      next: nextWeek == null
          ? null
          : WeeklyLimit.of(
              week: nextWeek,
              variableBudget: plan.variableCash,
              spending: spending,
            ),
      dueSoon: [
        for (final fixed in plan.fixed)
          if (!fixed.isPaid && _isWithinSevenDays(fixed.dueOn, today)) fixed,
      ],
    );
  }

  const new _({
    required this.today,
    required this.week,
    required this.next,
    required this.quietDays,
    required this.dueSoon,
  });

  /// O dia em que o resumo é lido.
  final LocalDate today;

  /// O limite e o gasto da semana.
  final WeeklyLimit week;

  /// O limite da semana seguinte, já contando esta; `null` quando o mês acaba
  /// nesta semana.
  final WeeklyLimit? next;

  /// Os dias da semana, até hoje, sem nenhum lançamento variável — só quando
  /// são três ou mais seguidos (RN-824).
  final List<LocalDate> quietDays;

  /// O que vence nos próximos sete dias.
  final List<FixedOccurrence> dueSoon;

  static bool _isWithinSevenDays(LocalDate due, LocalDate today) {
    final days = today.daysUntil(due);
    return days >= 0 && days <= 7;
  }

  /// O maior trecho de dias seguidos sem gasto de rotina, do início da semana
  /// até hoje. "Semana boa" pode ser só falta de lançamento, e o app não sabe
  /// a diferença — então informa, sem acusar.
  static List<LocalDate> _quietDays(
    WeeklyLimit week,
    MonthSpending spending,
    LocalDate today,
  ) {
    var longest = <LocalDate>[];
    var current = <LocalDate>[];
    final last = today.isBefore(week.week.end) ? today : week.week.end;
    for (var day = week.week.start; !day.isAfter(last); day = day.addDays(1)) {
      final spent = spending.routineBetween(day, day);
      current = spent.isZero ? [...current, day] : [];
      if (current.length > longest.length) longest = current;
    }
    return longest.length >= 3 ? longest : const [];
  }

  /// As frases do resumo, na ordem em que são lidas.
  List<String> get lines => [
    _headline,
    _difference,
    ?_nextWeek,
    ?_quiet,
    for (final fixed in dueSoon) _due(fixed),
  ];

  String _due(FixedOccurrence fixed) =>
      'Vence ${CalendarWords.weekday(fixed.dueOn)}, dia ${fixed.dueOn.day}: '
      '${fixed.expense.name}, ${MoneyFormat.brl(fixed.amount)}.';

  String get _headline {
    final range = 'Semana de ${week.week.start.day} a ${week.week.end.day}';
    return '$range: ${MoneyFormat.brl(week.spent)} de '
        '${MoneyFormat.brl(week.limit)}.';
  }

  String get _difference {
    final left = week.remaining;
    if (left.isNegative) {
      return 'A semana passou ${MoneyFormat.brl(-left)} do limite.';
    }
    return today.isBefore(week.week.end)
        ? 'Sobram ${MoneyFormat.brl(left)} até '
              '${CalendarWords.weekday(week.week.end)}.'
        : 'Sobraram ${MoneyFormat.brl(left)}.';
  }

  /// O limite seguinte e, se esta semana passou, quanto ele ficou menor do
  /// que seria (RN-822).
  String? get _nextWeek {
    final following = next;
    if (following == null) return null;
    final overrun = (-week.remaining).orZeroIfNegative;
    final limit = MoneyFormat.brl(following.limit);
    if (overrun.isZero) return 'Limite da próxima semana: $limit.';
    final smaller = following.limitWithout(overrun) - following.limit;
    return 'A próxima já considera isso: $limit. O limite ficou '
        '${MoneyFormat.brl(smaller)} menor do que seria.';
  }

  String? get _quiet {
    if (quietDays.isEmpty) return null;
    final from = CalendarWords.weekday(quietDays.first);
    final to = CalendarWords.weekday(quietDays.last);
    return 'Nenhum lançamento de $from a $to. Se faltou algum, dá para '
        'lançar agora com a data certa.';
  }
}
