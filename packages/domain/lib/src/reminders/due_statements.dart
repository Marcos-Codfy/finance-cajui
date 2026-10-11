import 'package:domain/src/budget/finances.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/card/card_statement.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/card/settlement.dart';
import 'package:domain/src/card/statement_cycle.dart';
import 'package:domain/src/debts/debt_schedule.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/reminders/due_item.dart';
import 'package:domain/src/reminders/due_window.dart';
import 'package:domain/src/reminders/reminder_target.dart';

/// As faturas que vencem na janela com algum valor em aberto (RN-1080,
/// RN-1084).
///
/// A fatura é sempre calculada das compras (RN-330), com as parcelas das
/// compras feitas antes do app, e o que está em aberto é ela menos o que
/// já foi pago dela. Paga inteira — ou sem compra nenhuma —, não há o que
/// lembrar.
abstract final class DueStatements {
  /// As faturas em aberto dos cartões [cards] com vencimento em [window].
  static List<DueItem> within(
    DueWindow window,
    Finances finances, {
    Iterable<CreditCard> cards = const [],
    Iterable<Settlement> settlements = const [],
  }) => [
    for (final card in cards)
      for (final closing in _closingMonths(window))
        if (StatementCycle.closingIn(card, closing) case final cycle
            when window.contains(cycle.dueOn))
          if (_open(cycle, finances, settlements) case final open
              when open.isPositive)
            DueItem(
              target: ReminderTarget.cards,
              id: card.id,
              name: card.name,
              amount: open,
              dueOn: cycle.dueOn,
            ),
  ];

  /// Os meses de fechamento cujas faturas podem vencer na janela: a fatura
  /// vence no mês em que fecha ou no seguinte (RN-304).
  static List<BudgetMonth> _closingMonths(DueWindow window) => [
    window.today.budgetMonth.previous,
    ...window.months,
  ];

  /// O que falta pagar da fatura do ciclo [cycle].
  static Money _open(
    StatementCycle cycle,
    Finances finances,
    Iterable<Settlement> settlements,
  ) {
    final statement = CardStatement.of(
      cycle,
      entries: finances.entries,
      reversals: finances.reversals,
      legacyInstallments: DebtSchedule.legacyCardInstallmentsDueIn(
        cycle.dueMonth,
        cardId: cycle.cardId,
        debts: finances.debts,
      ),
    );
    final paid = settlements
        .where((s) => s.cardId == cycle.cardId && s.dueMonth == cycle.dueMonth)
        .fold(Money.zero, (sum, settlement) => sum + settlement.amount);
    return statement.total - paid;
  }
}
