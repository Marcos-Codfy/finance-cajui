import 'package:domain/src/budget/finances.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/debts/debt.dart';
import 'package:domain/src/debts/debt_kind.dart';
import 'package:domain/src/reminders/due_item.dart';
import 'package:domain/src/reminders/due_window.dart';
import 'package:domain/src/reminders/reminder_target.dart';

/// As parcelas de dívida que vencem na janela e ainda não foram pagas
/// (RN-1080, RN-1083).
///
/// A parcela de compra feita no cartão antes do app fica de fora: ela é
/// cobrada na fatura, e a fatura tem o lembrete dela (RN-521).
abstract final class DueInstallments {
  /// As parcelas em aberto das dívidas de [finances] com vencimento em
  /// [window].
  static List<DueItem> within(DueWindow window, Finances finances) => [
    for (final debt in finances.openDebtsOn(window.today))
      if (debt.kind != DebtKind.cardInstallment)
        for (final month in window.months)
          if (_open(debt, month) case final index?)
            if (window.contains(month.dayClamped(debt.dueDay)))
              DueItem(
                target: ReminderTarget.debts,
                id: debt.id,
                name: debt.creditor,
                amount: debt.installmentDueIn(month),
                dueOn: month.dayClamped(debt.dueDay),
                detail: debt.informedBalance == null
                    ? 'Parcela ${index + 1} de ${debt.totalInstallments}'
                    : null,
              ),
  ];

  /// A posição da parcela de [month] — 0 para a primeira —, se ela existe e
  /// ainda está em aberto; nulo se não há parcela no mês ou se já foi paga.
  ///
  /// Paga é a parcela que a contagem de pagas já alcançou: as que a pessoa
  /// disse no cadastro e as que ela ligou à dívida depois (RN-520).
  static int? _open(Debt debt, BudgetMonth month) {
    if (!debt.installmentDueIn(month).isPositive) return null;
    final index = _firstDueMonth(debt).monthsUntil(month);
    return debt.paidInstallments > index ? null : index;
  }

  /// O mês da primeira parcela. Na dívida de saldo informado, é o primeiro
  /// vencimento depois do dia informado: informada no dia 11 com vencimento
  /// no 10, a deste mês já passou.
  static BudgetMonth _firstDueMonth(Debt debt) {
    final since = debt.informedOn;
    final dueThisMonth = debt.firstMonth.dayClamped(debt.dueDay);
    final passed = since != null && !dueThisMonth.isAfter(since);
    return passed ? debt.firstMonth.next : debt.firstMonth;
  }
}
