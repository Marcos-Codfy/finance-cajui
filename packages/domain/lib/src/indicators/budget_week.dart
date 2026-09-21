import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:meta/meta.dart';

/// Uma semana do orçamento: a semana de calendário, de segunda a domingo,
/// **recortada pelo mês**.
///
/// A semana partida pela virada do mês pertence a cada mês só pelos dias que
/// estão nele, e cada parte tem o seu próprio limite (RN-644): 28 a 30/09 é
/// uma semana de 3 dias em setembro; 01 a 04/10, uma de 4 dias em outubro.
@immutable
final class BudgetWeek {
  /// A semana do orçamento em que cai o dia [day].
  factory containing(LocalDate day) {
    final month = day.budgetMonth;
    final monday = day.addDays(1 - day.weekday);
    final sunday = monday.addDays(6);
    return BudgetWeek._(
      month: month,
      start: monday.isBefore(month.firstDay) ? month.firstDay : monday,
      end: sunday.isAfter(month.lastDay) ? month.lastDay : sunday,
    );
  }

  const new _({required this.month, required this.start, required this.end});

  /// O mês a que esta semana — ou este pedaço de semana — pertence.
  final BudgetMonth month;

  /// O primeiro dia: segunda-feira, ou o dia 1 do mês.
  final LocalDate start;

  /// O último dia: domingo, ou o último dia do mês.
  final LocalDate end;

  /// Quantos dias a semana tem dentro do mês.
  int get days => start.daysUntil(end) + 1;

  /// Quantos dias faltam no mês, contando a partir do início desta semana.
  int get daysLeftInMonth => start.daysUntil(month.lastDay) + 1;

  /// A semana seguinte dentro do mesmo mês, ou nulo se esta é a última.
  BudgetWeek? get next =>
      end == month.lastDay ? null : BudgetWeek.containing(end.addDays(1));

  @override
  bool operator ==(Object other) =>
      other is BudgetWeek && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
