import 'package:domain/src/calendar/budget_month.dart';
import 'package:meta/meta.dart';

/// Um dia do calendário, sem hora e sem fuso.
///
/// A data de uma compra é um dia, não um instante. Guardá-la como `DateTime`
/// convidaria o defeito clássico: o lançamento das 23h30 que cai no dia
/// seguinte — e às vezes no mês seguinte — quando o fuso muda.
@immutable
final class CalendarDay implements Comparable<CalendarDay> {
  /// Cria o dia. Data que não existe (30 de fevereiro) é erro de programa.
  new(this.year, this.month, this.day)
    : assert(
        DateTime.utc(year, month, day).day == day,
        'Data inexistente: $year-$month-$day',
      );

  /// O dia do calendário de um instante, no fuso em que ele já está.
  factory fromDateTime(DateTime moment) =>
      CalendarDay(moment.year, moment.month, moment.day);

  /// O ano, com quatro dígitos.
  final int year;

  /// O mês, de 1 a 12.
  final int month;

  /// O dia do mês, de 1 a 31.
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// O mês de competência a que o dia pertence.
  BudgetMonth get budgetMonth => BudgetMonth(year, month);

  /// O dia da semana, de 1 (segunda) a 7 (domingo).
  int get weekday => _utc.weekday;

  /// Este dia mais [days] dias; negativo volta no tempo.
  CalendarDay addDays(int days) =>
      CalendarDay.fromDateTime(_utc.add(Duration(days: days)));

  /// Quantos dias vão deste dia até [other]. Negativo se [other] vem antes.
  int daysUntil(CalendarDay other) => other._utc.difference(_utc).inDays;

  /// Vem antes de [other].
  bool isBefore(CalendarDay other) => compareTo(other) < 0;

  /// Vem depois de [other].
  bool isAfter(CalendarDay other) => compareTo(other) > 0;

  @override
  int compareTo(CalendarDay other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is CalendarDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// No formato ISO, `2026-09-12`: é também como o dia é gravado.
  @override
  String toString() =>
      '${'$year'.padLeft(4, '0')}-${'$month'.padLeft(2, '0')}-'
      '${'$day'.padLeft(2, '0')}';
}
