import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';

/// Os nomes de dia e de mês que os modelos de frase usam.
///
/// Só palavras, sem regra de negócio: existe para "até domingo" e "setembro"
/// saírem iguais no app e no servidor.
abstract final class CalendarWords {
  static const _weekdays = [
    'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo', //
  ];

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  /// "domingo"
  static String weekday(LocalDate day) => _weekdays[day.weekday - 1];

  /// "setembro"
  static String month(BudgetMonth month) => _months[month.month - 1];

  /// "Setembro", para abrir frase.
  static String monthCapitalized(BudgetMonth month) {
    final name = CalendarWords.month(month);
    return name[0].toUpperCase() + name.substring(1);
  }
}
