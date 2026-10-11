import 'package:domain/src/budget/budget_plan.dart';
import 'package:domain/src/budget/month_actuals.dart';
import 'package:domain/src/budget/month_budget.dart';
import 'package:domain/src/budget/month_record.dart';
import 'package:domain/src/budget/plan_suggestion.dart';
import 'package:domain/src/budget/week_allowance.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/card/card_month_usage.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/debts/debt.dart';
import 'package:domain/src/debts/debt_calendar.dart';
import 'package:domain/src/debts/debt_order.dart';
import 'package:domain/src/debts/debt_schedule.dart';
import 'package:domain/src/income/income_receipt.dart';
import 'package:domain/src/income/month_income.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Os números da casa, a partir dos fatos: o mês, a semana, os cartões, as
/// dívidas e o histórico. É a mesma conta no celular, na web e no servidor —
/// quem monta os fatos é cada um; quem conta é aqui.
@immutable
final class Finances {
  /// Cria a visão. [plans] são todos os planos já definidos, para que cada
  /// mês do histórico use o plano que valia nele; [excluded] são lançamentos
  /// que contam pela dívida — o pagamento de parcela ligado a ela.
  const new({
    required this.categories,
    required this.plans,
    this.entries = const [],
    this.reversals = const [],
    this.receipts = const [],
    this.debts = const [],
    this.debtOrder = const [],
    this.excluded = const {},
  });

  /// As categorias, por identificador.
  final Map<String, Category> categories;

  /// Os planos, em qualquer ordem.
  final List<BudgetPlan> plans;

  /// Os lançamentos que valem: corrigidos, sem os cancelados.
  final List<Entry> entries;

  /// Os estornos.
  final List<Reversal> reversals;

  /// As rendas recebidas.
  final List<IncomeReceipt> receipts;

  /// As dívidas cadastradas.
  final List<Debt> debts;

  /// A ordem de quitação, em identificadores.
  final List<String> debtOrder;

  /// Lançamentos que não contam como gasto do mês.
  final Set<String> excluded;

  /// O plano que vale hoje: o mais novo.
  BudgetPlan get plan => _newest(plans) ?? BudgetPlan.empty;

  /// O mais novo de [candidates]; no empate — planos antigos não têm data —,
  /// vale o que chegou por último, que é a ordem dos fatos.
  static BudgetPlan? _newest(Iterable<BudgetPlan> candidates) =>
      candidates.isEmpty
      ? null
      : candidates.reduce((a, b) => a.isNewerThan(b) ? a : b);

  /// O plano que valia em [month]: o mais novo definido até o fim dele. Um
  /// mês anterior a todo plano usa o primeiro, para o histórico não começar
  /// vazio só porque o plano veio depois dos lançamentos.
  BudgetPlan planFor(BudgetMonth month) {
    final end = DateTime.utc(month.next.year, month.next.month);
    final before = plans.where((plan) {
      final at = plan.definedAt;
      return at == null || at.isBefore(end);
    });
    return _newest(before) ?? _oldest ?? BudgetPlan.empty;
  }

  BudgetPlan? get _oldest =>
      plans.isEmpty ? null : plans.reduce((a, b) => b.isNewerThan(a) ? a : b);

  /// O que entra em dinheiro em [month]: cada salário (o recebido, se já
  /// houve; senão o esperado) e as entradas avulsas.
  Money cashIncomeIn(BudgetMonth month) => MonthIncome.of(
    month,
    sources: planFor(month).salaries,
    receipts: receipts,
  ).amounts.cash;

  /// O vale de [month]: o que entrou de vale, se já foi registrado; senão o
  /// do plano.
  Money voucherIn(BudgetMonth month) {
    final credited = receipts
        .where((r) => r.tender == Tender.mealVoucher)
        .where((r) => month.contains(r.receivedOn))
        .fold(Money.zero, (sum, r) => sum + r.amount);
    return credited.isPositive ? credited : planFor(month).voucher;
  }

  /// O mês [month] inteiro.
  MonthBudget budgetFor(BudgetMonth month) => MonthBudget.of(
    month: month,
    plan: planFor(month),
    categories: categories,
    spent: MonthActuals.byCategory(
      month,
      entries: entries,
      reversals: reversals,
      excluded: excluded,
    ),
    cashIncome: cashIncomeIn(month),
    voucher: voucherIn(month),
    debtInstallments: DebtSchedule.dueIn(month, debts: debts, entries: entries),
  );

  /// A semana de [today].
  WeekAllowance weekOf(LocalDate today) => WeekAllowance.of(
    limit: budgetFor(today.budgetMonth).weeklyLimit,
    today: today,
    entries: entries,
    categories: categories,
    excluded: excluded,
  );

  /// A linha de [month] no "Mês a mês".
  MonthRecord recordOf(BudgetMonth month) => MonthRecord(
    month: month,
    cameIn: cashIncomeIn(month),
    wentOut: budgetFor(month).outOfPocket,
    stillOwed: DebtCalendar.owedAtEndOf(month, debts: debts, entries: entries),
  );

  /// O "Mês a mês", do primeiro mês com algum fato até [until], o mais
  /// recente primeiro.
  List<MonthRecord> history(BudgetMonth until) {
    final first = _firstMonth;
    if (first == null || first.isAfter(until)) return const [];
    return [
      for (var month = until; !month.isBefore(first); month = month.previous)
        recordOf(month),
    ];
  }

  BudgetMonth? get _firstMonth {
    final months = [
      for (final entry in entries) entry.occurredOn.budgetMonth,
      for (final receipt in receipts) receipt.receivedOn.budgetMonth,
    ];
    if (months.isEmpty) return null;
    return months.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// As dívidas que ainda têm saldo, na ordem de quitação.
  List<Debt> openDebtsOn(LocalDate day) => DebtOrder.apply(
    debts.where((debt) => DebtCalendar.outstandingOn(debt, day).isPositive),
    debtOrder,
  );

  /// Quanto ainda se deve no fim de [day]: dívidas e parcelas de cartão.
  Money owedOn(LocalDate day) =>
      DebtCalendar.owedAtEndOf(day.budgetMonth, debts: debts, entries: entries);

  /// O uso de [card] em [month]; nulo sem limite informado.
  CardMonthUsage? cardUsage(CreditCard card, BudgetMonth month) =>
      CardMonthUsage.of(card, month, entries: entries, reversals: reversals);

  /// "Minhas contas" sugeridas, quando cabe sugerir.
  PlanSuggestion? suggestion(LocalDate today) => PlanSuggestion.of(
    plan: plan,
    entries: entries,
    categories: categories,
    today: today,
  );
}
