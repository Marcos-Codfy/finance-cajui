import 'package:domain/src/calendar/budget_month.dart';
import 'package:meta/meta.dart';

/// A vigência de algo que vale "a partir de um mês": um fixo, uma faixa, um
/// valor.
///
/// No Cajui nada é alterado para trás. Mudar o aluguel a partir de janeiro é
/// encerrar a vigência antiga em janeiro e abrir outra — dezembro e os
/// fechamentos anteriores não mudam (RN-412, RN-415 e RN-427).
@immutable
final class MonthSpan {
  /// Cria a vigência. Sem [from], vale desde sempre; sem [until], para sempre.
  const new({this.from, this.until});

  /// Sempre vigente.
  static const always = MonthSpan();

  /// O primeiro mês em que vale.
  final BudgetMonth? from;

  /// O primeiro mês em que **deixa** de valer.
  final BudgetMonth? until;

  /// Vale no mês [month].
  bool contains(BudgetMonth month) {
    final start = from;
    final end = until;
    final started = start == null || !month.isBefore(start);
    final notEnded = end == null || month.isBefore(end);
    return started && notEnded;
  }
}
