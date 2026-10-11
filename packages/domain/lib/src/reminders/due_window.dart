import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:meta/meta.dart';

/// Os dias em que um vencimento ganha lembrete: de hoje até [until],
/// inclusive (RN-1081).
///
/// Vencimento de ontem não entra: lembrete depois do vencimento é cobrança
/// (RN-840).
@immutable
final class DueWindow {
  /// A janela que começa em [today] e dura [days] dias depois dele.
  factory from(LocalDate today, {required int days}) =>
      DueWindow._(today, today.addDays(days));

  const new _(this.today, this.until);

  /// O primeiro dia: hoje.
  final LocalDate today;

  /// O último dia.
  final LocalDate until;

  /// Se [day] cai na janela.
  bool contains(LocalDate day) => !day.isBefore(today) && !day.isAfter(until);

  /// Os meses que a janela toca, do mais antigo ao mais novo.
  List<BudgetMonth> get months => [
    for (
      var month = today.budgetMonth;
      !month.isAfter(until.budgetMonth);
      month = month.next
    )
      month,
  ];
}
