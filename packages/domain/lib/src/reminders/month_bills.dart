import 'package:domain/src/budget/budget_line.dart';
import 'package:domain/src/budget/finances.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/reminders/due_bills.dart';
import 'package:domain/src/reminders/due_window.dart';

/// Uma conta do mês na linha do tempo: a linha da planilha, quando vence e
/// se já foi paga.
typedef MonthBill = ({BudgetLine line, LocalDate dueOn, bool paid});

/// As contas com vencimento de um mês, pagas e a pagar, por data (17/10/2026)
/// — a linha do tempo do Meu mês.
///
/// "Paga" é a mesma conta dos lembretes (`DueBills`): o gasto da categoria
/// no mês cobre a conta, na ordem do vencimento. O que se paga no cartão
/// fica de fora: vai na fatura.
abstract final class MonthBills {
  /// As contas de [month] em [finances]; [cardIds] são os cartões.
  static List<MonthBill> of(
    Finances finances,
    BudgetMonth month, {
    Set<String> cardIds = const {},
  }) {
    final window = DueWindow.from(month.firstDay, days: month.length - 1);
    final open = {
      for (final item in DueBills.within(window, finances, cardIds: cardIds))
        item.id,
    };
    return [
      for (final line in finances.planFor(month).lines)
        if (_dueDay(line, cardIds) case final day?)
          (
            line: line,
            dueOn: month.dayClamped(day),
            paid: !open.contains(line.id),
          ),
    ]..sort((a, b) => a.dueOn.compareTo(b.dueOn));
  }

  static int? _dueDay(BudgetLine line, Set<String> cardIds) {
    final day = line.dueDay;
    if (day == null || day < 1 || !line.amount.isPositive) return null;
    return cardIds.contains(line.paymentMethodId) ? null : day;
  }
}
