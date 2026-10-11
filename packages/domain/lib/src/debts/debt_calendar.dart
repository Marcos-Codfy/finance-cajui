import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/debts/debt.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money.dart';

/// O saldo de uma dívida pelo calendário: a parcela de dívida nunca é
/// digitada (regra 3 da planilha), então quem diz quanto ainda se deve é o
/// vencimento que passou.
///
/// Na parcelada, conta o maior entre as parcelas que a pessoa disse ter
/// pago no cadastro e as que já venceram. Na de saldo informado — a conta
/// atrasada, o rotativo —, o saldo cai uma parcela a cada vencimento
/// depois do dia em que foi informado, e nunca fica negativo.
abstract final class DebtCalendar {
  /// Quanto ainda se deve de [debt] ao fim de [day].
  static Money outstandingOn(Debt debt, LocalDate day) {
    final balance = debt.informedBalance;
    if (balance != null) return _balanceOn(debt, balance, day);
    final due = _installmentsDueBy(debt, day);
    final paid = due > debt.paidInstallments ? due : debt.paidInstallments;
    final left = debt.totalInstallments - paid;
    return left > 0 ? debt.installmentAmount * left : Money.zero;
  }

  /// A parcela de [month] de uma dívida de saldo informado: a parcela, ou o
  /// que resta se for menos; zero antes do dia informado ou quitada.
  static Money balanceDueIn(Debt debt, BudgetMonth month) {
    final balance = debt.informedBalance ?? Money.zero;
    final installment = debt.installmentAmount;
    final since = debt.informedOn;
    if (!installment.isPositive || since == null) return Money.zero;
    final dueOn = month.dayClamped(debt.dueDay);
    if (!dueOn.isAfter(since)) return Money.zero;
    final before = _balanceOn(debt, balance, dueOn.addDays(-1));
    return before < installment ? before : installment;
  }

  /// Quanto ainda se deve ao fim de [month], somando as dívidas e as
  /// parcelas de cartão que vencem depois dele.
  static Money owedAtEndOf(
    BudgetMonth month, {
    required Iterable<Debt> debts,
    Iterable<Entry> entries = const [],
  }) {
    final last = month.lastDay;
    final fromDebts = debts.fold(
      Money.zero,
      (sum, debt) => sum + outstandingOn(debt, last),
    );
    final fromCards = entries.fold(
      Money.zero,
      (sum, entry) =>
          sum +
          (entry.installmentPlan?.committedFrom(month.next) ?? Money.zero),
    );
    return fromDebts + fromCards;
  }

  static int _installmentsDueBy(Debt debt, LocalDate day) {
    var count = 0;
    for (var k = 0; k < debt.totalInstallments; k++) {
      final dueOn = debt.firstMonth.addMonths(k).dayClamped(debt.dueDay);
      if (dueOn.isAfter(day)) break;
      count++;
    }
    return count;
  }

  static Money _balanceOn(Debt debt, Money balance, LocalDate day) {
    final since = debt.informedOn;
    if (since == null || !day.isAfter(since)) return balance;
    final paid = debt.installmentAmount * _dueDaysBetween(debt, since, day);
    return (balance - paid).orZeroIfNegative;
  }

  /// Quantos vencimentos caem depois de [after] e até [until], inclusive.
  static int _dueDaysBetween(Debt debt, LocalDate after, LocalDate until) {
    var count = 0;
    var month = after.budgetMonth;
    while (!month.isAfter(until.budgetMonth)) {
      final dueOn = month.dayClamped(debt.dueDay);
      if (dueOn.isAfter(after) && !dueOn.isAfter(until)) count++;
      month = month.next;
    }
    return count;
  }
}
