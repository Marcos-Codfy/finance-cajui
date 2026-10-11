import 'package:domain/src/budget/budget_line.dart';
import 'package:domain/src/budget/finances.dart';
import 'package:domain/src/budget/month_actuals.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/reminders/due_item.dart';
import 'package:domain/src/reminders/due_window.dart';
import 'package:domain/src/reminders/reminder_target.dart';

/// As contas de "Minhas contas" que vencem na janela e ainda não foram pagas
/// (RN-1080, RN-1082).
///
/// O plano não liga lançamento a conta: o que diz que o aluguel foi pago é
/// o gasto lançado na categoria dele. Como várias contas dividem uma
/// categoria — "Água, luz e internet" —, o gasto do mês paga as contas na
/// ordem do vencimento, e só conta como paga a que ficou coberta inteira.
/// Na dúvida, o lembrete vai: lembrete a mais incomoda, lembrete a menos
/// custa multa.
abstract final class DueBills {
  /// As contas em aberto de [finances] com vencimento em [window]. As linhas
  /// pagas num dos cartões de [cardIds] não têm lembrete próprio: quem vence
  /// é a fatura.
  static List<DueItem> within(
    DueWindow window,
    Finances finances, {
    Set<String> cardIds = const {},
  }) => [
    for (final month in window.months)
      for (final (line, day) in _unpaid(finances, month, cardIds))
        if (window.contains(month.dayClamped(day)))
          DueItem(
            target: ReminderTarget.bills,
            id: line.id,
            name: line.name,
            amount: line.amount,
            dueOn: month.dayClamped(day),
          ),
  ];

  /// As linhas com lembrete que o gasto de [month] não cobre, com o dia de
  /// vencimento de cada uma.
  static List<(BudgetLine, int)> _unpaid(
    Finances finances,
    BudgetMonth month,
    Set<String> cardIds,
  ) {
    final spent = MonthActuals.byCategory(
      month,
      entries: finances.entries,
      reversals: finances.reversals,
      excluded: finances.excluded,
    );
    final lines = finances.planFor(month).lines;
    return [
      for (final categoryId in {for (final line in lines) line.categoryId})
        ..._uncovered(
          [
            for (final line in lines)
              if (line.categoryId == categoryId) line,
          ],
          spent[categoryId] ?? Money.zero,
          cardIds,
        ),
    ];
  }

  /// O gasto [spent] da categoria paga primeiro as linhas sem lembrete
  /// próprio — elas podem já ter sido pagas, e o lembrete erra para o lado
  /// de avisar — e depois as com dia, do vencimento mais cedo ao mais tarde.
  /// A primeira que não fica coberta inteira, e todas as seguintes, estão
  /// em aberto.
  static List<(BudgetLine, int)> _uncovered(
    List<BudgetLine> lines,
    Money spent,
    Set<String> cardIds,
  ) {
    final dated = [
      for (final line in lines)
        if (_dueDayOf(line, cardIds) case final day?) (line, day),
    ]..sort((a, b) => _byDueDay(a, b, lines));
    var left = lines
        .where((line) => _dueDayOf(line, cardIds) == null)
        .fold(spent, (rest, line) => rest - line.amount);
    final open = <(BudgetLine, int)>[];
    for (final item in dated) {
      final amount = item.$1.amount;
      final covered = open.isEmpty && left >= amount;
      if (covered) left -= amount;
      if (!covered) open.add(item);
    }
    return open;
  }

  /// O dia de vencimento de [line], se ela tem lembrete: tem dia, tem valor
  /// e não é paga no cartão. Linha sem valor não tem o que avisar nem como
  /// saber se foi paga.
  static int? _dueDayOf(BudgetLine line, Set<String> cardIds) {
    final day = line.dueDay;
    if (day == null || day < 1 || !line.amount.isPositive) return null;
    return cardIds.contains(line.paymentMethodId) ? null : day;
  }

  /// O vencimento mais cedo primeiro; no empate, a ordem do plano.
  static int _byDueDay(
    (BudgetLine, int) a,
    (BudgetLine, int) b,
    List<BudgetLine> lines,
  ) {
    final byDay = a.$2.compareTo(b.$2);
    return byDay != 0 ? byDay : lines.indexOf(a.$1) - lines.indexOf(b.$1);
  }
}
