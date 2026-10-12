import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';

/// As datas de um extrato, que quase nunca trazem o ano (RN-1105).
///
/// O extrato escreve "05/10" ou "05 OUT": o ano é o do mês do extrato. Na
/// virada, um extrato de janeiro traz linhas de dezembro, que são do ano
/// anterior — o ano certo é o que deixa a linha mais perto do período.
abstract final class StatementDates {
  /// O dia [day]/[month] num extrato de [period], com [year] quando a linha
  /// o trouxe. `null` quando o dia não existe ou cai depois de [today]: um
  /// extrato não tem movimentação no futuro.
  static LocalDate? resolve({
    required int day,
    required int month,
    required BudgetMonth period,
    required LocalDate today,
    int? year,
  }) {
    if (month < 1 || month > 12 || day < 1) return null;
    final chosen = year ?? _nearest(month, period);
    if (day > BudgetMonth(chosen, month).length) return null;
    final date = LocalDate(chosen, month, day);
    return date.isAfter(today) ? null : date;
  }

  /// O ano que deixa [month] mais perto de [period]: setembro num extrato
  /// de outubro é do mesmo ano; dezembro num de janeiro, do anterior.
  static int _nearest(int month, BudgetMonth period) {
    final candidates = [period.year - 1, period.year, period.year + 1];
    int distance(int year) =>
        ((year - period.year) * 12 + month - period.month).abs();
    candidates.sort((a, b) => distance(a).compareTo(distance(b)));
    return candidates.first;
  }

  /// Se o dia [day] do mês [month] está escrito em [text] do jeito que um
  /// extrato escreve: "05/10", "5/10", "05-10", "05.10", "05 OUT",
  /// "05/OUT", "05OUT" ou "2026-10-05". Serve para conferir a data que a IA
  /// devolveu contra o texto, como o valor (RN-774).
  static bool writtenIn(String text, {required int day, required int month}) {
    final upper = text.toUpperCase();
    final dd = day.toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    final name = _months[month - 1];
    final forms = [
      for (final d in {dd, '$day'}) ...[
        '$d/$mm',
        '$d-$mm',
        '$d.$mm',
        '$d $name',
        '$d/$name',
        '$d$name',
      ],
    ];
    return forms.any((form) => _standsAlone(upper, form)) ||
        _isoIn(upper, '-$mm-$dd');
  }

  /// "2026-10-05": o ano vem colado antes, então a conferência é outra —
  /// dígito antes do traço, e nada de dígito depois do dia.
  static bool _isoIn(String text, String form) {
    var at = text.indexOf(form);
    while (at >= 0) {
      final end = at + form.length;
      final year = at > 0 && _isDigit(text[at - 1]);
      final after = end == text.length || !_isDigit(text[end]);
      if (year && after) return true;
      at = text.indexOf(form, at + 1);
    }
    return false;
  }

  /// [form] aparece em [text] sem dígito colado antes ou depois: "15/10"
  /// não conta como "5/10".
  static bool _standsAlone(String text, String form) {
    var at = text.indexOf(form);
    while (at >= 0) {
      final end = at + form.length;
      final before = at == 0 || !_isDigit(text[at - 1]);
      final after = end == text.length || !_isDigit(text[end]);
      if (before && after) return true;
      at = text.indexOf(form, at + 1);
    }
    return false;
  }

  static bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  static const _months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];
}
