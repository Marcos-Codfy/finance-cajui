import 'package:domain/src/calendar/calendar_day.dart';
import 'package:meta/meta.dart';

/// O mês de competência: a unidade em que o Cajui planeja e fecha as contas.
@immutable
final class BudgetMonth implements Comparable<BudgetMonth> {
  /// Cria o mês [month] (1 a 12) de [year].
  const new(this.year, this.month)
    : assert(month >= 1 && month <= 12, 'Mês fora de 1 a 12.');

  /// O mês a partir da contagem corrida de meses desde o ano zero: é o que
  /// deixa somar e subtrair meses sem tratar a virada de ano caso a caso.
  factory _fromIndex(int index) => BudgetMonth(index ~/ 12, index % 12 + 1);

  /// O ano, com quatro dígitos.
  final int year;

  /// O mês, de 1 a 12.
  final int month;

  int get _index => year * 12 + (month - 1);

  /// O mês seguinte.
  BudgetMonth get next => BudgetMonth._fromIndex(_index + 1);

  /// O mês anterior.
  BudgetMonth get previous => BudgetMonth._fromIndex(_index - 1);

  /// Este mês mais [months] meses.
  BudgetMonth addMonths(int months) => BudgetMonth._fromIndex(_index + months);

  /// Quantos meses vão deste até [other]. Negativo se [other] vem antes.
  int monthsUntil(BudgetMonth other) => other._index - _index;

  /// O primeiro dia do mês.
  CalendarDay get firstDay => CalendarDay(year, month, 1);

  /// O último dia do mês.
  CalendarDay get lastDay => next.firstDay.addDays(-1);

  /// Quantos dias o mês tem.
  int get length => lastDay.day;

  /// O dia [day] deste mês; se o mês for mais curto, o último dia dele.
  ///
  /// É a regra de quem tem vencimento no dia 31: em fevereiro, vence no
  /// último dia do mês.
  CalendarDay dayClamped(int day) {
    final last = length;
    return CalendarDay(year, month, day > last ? last : day);
  }

  /// O dia [day] pertence a este mês.
  bool contains(CalendarDay day) => day.year == year && day.month == month;

  /// Vem antes de [other].
  bool isBefore(BudgetMonth other) => _index < other._index;

  /// Vem depois de [other].
  bool isAfter(BudgetMonth other) => _index > other._index;

  @override
  int compareTo(BudgetMonth other) => _index.compareTo(other._index);

  @override
  bool operator ==(Object other) =>
      other is BudgetMonth && other._index == _index;

  @override
  int get hashCode => _index.hashCode;

  /// No formato ISO, `2026-09`.
  @override
  String toString() => '${'$year'.padLeft(4, '0')}-${'$month'.padLeft(2, '0')}';
}
