import 'package:domain/src/budget/finances.dart';
import 'package:domain/src/budget/month_budget.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/card/settlement.dart';
import 'package:domain/src/reminders/due_bills.dart';
import 'package:domain/src/reminders/due_installments.dart';
import 'package:domain/src/reminders/due_item.dart';
import 'package:domain/src/reminders/due_reminder.dart';
import 'package:domain/src/reminders/due_statements.dart';
import 'package:domain/src/reminders/due_window.dart';
import 'package:domain/src/reminders/reminder_moment.dart';
import 'package:domain/src/reminders/reminder_words.dart';

/// Os lembretes de vencimento das próximas semanas (RN-840 a RN-849 e
/// RN-1080 a RN-1088): contas, parcelas e faturas em aberto, cada uma dois
/// dias antes e no dia, às 9h.
///
/// É função pura do livro e do dia: o app refaz a lista a cada mudança e
/// entrega ao aparelho, que só marca. Conta paga depois de publicada some
/// na próxima publicação.
abstract final class DueReminders {
  /// Quantos dias à frente a lista olha: um mês inteiro e uma semana de
  /// folga, para o app que fica dias sem abrir não perder o vencimento.
  static const horizonDays = 35;

  /// A hora em que todo lembrete chega: cedo o bastante para pagar no dia.
  static const hour = 9;

  /// Os lembretes de [finances] a partir de [today], do mais cedo ao mais
  /// tarde. [cards] e [settlements] são os cartões e o que já foi pago das
  /// faturas, que o plano não guarda.
  static List<DueReminder> upcoming(
    Finances finances, {
    required LocalDate today,
    Iterable<CreditCard> cards = const [],
    Iterable<Settlement> settlements = const [],
  }) {
    final window = DueWindow.from(today, days: horizonDays);
    final budgets = <BudgetMonth, MonthBudget>{};
    MonthBudget budgetOf(BudgetMonth month) =>
        budgets.putIfAbsent(month, () => finances.budgetFor(month));
    return [
      for (final item in _items(window, finances, cards, settlements))
        for (final moment in ReminderMoment.values)
          if (!_fireOn(item, moment).isBefore(today))
            _reminder(item, moment, budgetOf(item.dueOn.budgetMonth)),
    ]..sort(_byTime);
  }

  /// O que vence na janela e está em aberto, nos três calendários.
  static List<DueItem> _items(
    DueWindow window,
    Finances finances,
    Iterable<CreditCard> cards,
    Iterable<Settlement> settlements,
  ) => [
    ...DueBills.within(
      window,
      finances,
      cardIds: {for (final card in cards) card.id},
    ),
    ...DueInstallments.within(window, finances),
    ...DueStatements.within(
      window,
      finances,
      cards: cards,
      settlements: settlements,
    ),
  ];

  static LocalDate _fireOn(DueItem item, ReminderMoment moment) =>
      item.dueOn.addDays(-moment.daysBefore);

  static DueReminder _reminder(
    DueItem item,
    ReminderMoment moment,
    MonthBudget budget,
  ) => DueReminder(
    id: '${item.eventKey}:${moment.daysBefore}',
    eventKey: item.eventKey,
    fireOn: _fireOn(item, moment),
    hour: hour,
    dueOn: item.dueOn,
    title: ReminderWords.title(item, moment),
    text: ReminderWords.text(item, budget),
    publicTitle: ReminderWords.publicTitle(item, moment),
    publicText: ReminderWords.publicText,
    target: item.target,
    // Mês com falta: um aviso por vencimento, nunca dois (RN-846).
    oncePerEvent: !budget.closes,
  );

  static int _byTime(DueReminder a, DueReminder b) {
    final byDay = a.fireOn.compareTo(b.fireOn);
    return byDay != 0 ? byDay : a.id.compareTo(b.id);
  }
}
