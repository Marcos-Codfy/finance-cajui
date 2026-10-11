import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';

/// O fuso de negócio do Cajui: o horário de Brasília, sem horário de verão.
///
/// Os carimbos de edição são gravados em UTC, mas o mês da pessoa vira à
/// meia-noite daqui. Sem isso, o plano salvo às 22h do dia 31 caía no mês
/// seguinte — em UTC já era dia 1.
abstract final class BusinessTime {
  /// A diferença para o UTC.
  static const Duration offset = Duration(hours: -3);

  /// O dia, no fuso de negócio, do instante [moment].
  static LocalDate dateOf(DateTime moment) =>
      LocalDate.fromDateTime(moment.toUtc().add(offset));

  /// O instante, em UTC, em que [month] começa no fuso de negócio.
  static DateTime startOf(BudgetMonth month) =>
      DateTime.utc(month.year, month.month).subtract(offset);
}
