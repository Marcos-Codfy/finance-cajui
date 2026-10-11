import 'package:domain/src/budget/month_budget.dart';
import 'package:domain/src/calendar/calendar_words.dart';
import 'package:domain/src/money/money_format.dart';
import 'package:domain/src/reminders/due_item.dart';
import 'package:domain/src/reminders/reminder_moment.dart';
import 'package:domain/src/reminders/reminder_target.dart';

/// As frases dos lembretes de vencimento (RN-1085), no tom do guia de voz:
/// fato, valor e o que o mês fica sendo — nunca "pague já", nunca alarme.
///
/// O efeito sobre o mês é o resultado projetado do mês do vencimento, que
/// já conta o item: o app não conhece o saldo da conta de ninguém, e por
/// isso a frase se declara estimativa — "pelo que está lançado" (RN-841).
abstract final class ReminderWords {
  /// O que aparece na tela bloqueada no lugar do texto (RN-843).
  static const publicText = 'Desbloqueie para ver o valor.';

  /// "Aluguel vence sábado, 10", "Carnê da loja: parcela vence hoje".
  static String title(DueItem item, ReminderMoment moment) =>
      '${_subject(item)} vence ${_when(item, moment)}';

  /// O título da tela bloqueada, sem nome e sem valor: "Uma conta vence
  /// sábado, 10".
  static String publicTitle(DueItem item, ReminderMoment moment) =>
      '${_kind(item.target)} vence ${_when(item, moment)}';

  /// O valor, o efeito sobre o mês do vencimento em [budget] e, se pagar
  /// deixa o mês com falta, onde rever (RN-842).
  static String text(DueItem item, MonthBudget budget) => [
    _amount(item),
    _effect(budget),
    if (!budget.closes) _whereToLook(item.target),
  ].join(' ');

  static String _subject(DueItem item) => switch (item.target) {
    ReminderTarget.bills => item.name,
    ReminderTarget.debts => '${item.name}: parcela',
    ReminderTarget.cards => '${item.name}: fatura',
  };

  static String _kind(ReminderTarget target) => switch (target) {
    ReminderTarget.bills => 'Uma conta',
    ReminderTarget.debts => 'Uma parcela',
    ReminderTarget.cards => 'Uma fatura',
  };

  static String _when(DueItem item, ReminderMoment moment) =>
      moment == ReminderMoment.onTheDay
      ? 'hoje'
      : '${CalendarWords.weekday(item.dueOn)}, ${item.dueOn.day}';

  /// A fatura avisa que as compras já contaram: pagar a fatura não é gastar
  /// de novo (RN-340).
  static String _amount(DueItem item) {
    final amount = MoneyFormat.brl(item.amount);
    final detail = item.detail;
    return switch (item.target) {
      ReminderTarget.cards =>
        '$amount. As compras já contam no mês em que foram feitas.',
      _ when detail != null => '$detail, $amount.',
      _ => '$amount.',
    };
  }

  static String _effect(MonthBudget budget) {
    final month = CalendarWords.month(budget.month);
    final result = budget.result;
    if (result.isNegative) {
      return 'Pelo que está lançado, depois de pagar faltam '
          '${MoneyFormat.brl(budget.shortfall)} para fechar $month.';
    }
    if (result.isZero) {
      return 'Pelo que está lançado, $month fecha sem sobra depois de pagar.';
    }
    return 'Pelo que está lançado, $month continua com sobra de '
        '${MoneyFormat.brl(result)} depois de pagar.';
  }

  /// Os ajustes moram em Minhas contas; o que negociar, nas dívidas.
  static String _whereToLook(ReminderTarget target) =>
      target == ReminderTarget.debts
      ? 'Dá para rever em Minhas dívidas.'
      : 'Dá para rever em Minhas contas.';
}
