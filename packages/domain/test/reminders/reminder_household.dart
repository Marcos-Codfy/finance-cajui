import 'package:domain/domain.dart';

import '../support/household.dart';

/// A casa dos lembretes: a mesma renda da casa de sempre, com as contas da
/// planilha ganhando dia de vencimento.
///
/// Outubro de 2026, com o plano inteiro: entra 3.300,00; sai 1.350,00 de
/// contas fixas, 70,00 de assinaturas, 1.000,00 de dia a dia, 120,00 do
/// carnê e 330,00 de dízimo — 2.870,00 —, dos quais o vale cobre 500,00.
/// Sobra de 3.300,00 − 2.370,00 = 930,00. Novembro, sem lançamento, igual.

/// Quarta, 7 de outubro de 2026.
final LocalDate reminderToday = LocalDate(2026, 10, 7);

BudgetLine _line(
  String id,
  int cents,
  String category, {
  int? dueDay,
  LineGroup group = LineGroup.fixedBill,
  String? paidWith,
}) => BudgetLine.create(
  id: id,
  name: id,
  amount: Money.fromCents(cents),
  group: group,
  categoryId: category,
  dueDay: dueDay,
  paymentMethodId: paidWith,
).valueOrNull!;

/// O plano: Aluguel dia 10; Água, Luz e Internet — a mesma categoria — nos
/// dias 10, 15 e 20; Streaming sem dia; Nuvem no dia 12; Música no dia 12,
/// paga no cartão.
BudgetPlan reminderPlan({int firstSalary = 180000}) => BudgetPlan(
  salaries: [salary('salary-a', firstSalary), salary('salary-b', 150000)],
  voucher: const Money.fromCents(50000),
  titheBasisPoints: 1000,
  lines: [
    _line('Aluguel', 100000, 'rent', dueDay: 10),
    _line('Água', 8000, 'utilities', dueDay: 10),
    _line('Luz', 18000, 'utilities', dueDay: 15),
    _line('Internet', 9000, 'utilities', dueDay: 20),
    _line('Streaming', 4000, 'subscriptions', group: LineGroup.subscription),
    _line(
      'Nuvem',
      1000,
      'subscriptions',
      dueDay: 12,
      group: LineGroup.subscription,
    ),
    _line(
      'Música',
      2000,
      'subscriptions',
      dueDay: 12,
      group: LineGroup.subscription,
      paidWith: 'nubank',
    ),
    _line('Transporte', 40000, 'transport', group: LineGroup.dayToDay),
    _line('Mercado', 60000, 'groceries', group: LineGroup.dayToDay),
  ],
);

/// O carnê: 10 parcelas de 120,00 desde outubro, no dia 10.
Debt carneDebt({int paid = 0}) => Debt.create(
  id: 'carne',
  creditor: 'Carnê da loja',
  kind: DebtKind.informal,
  installmentAmount: const Money.fromCents(12000),
  totalInstallments: 10,
  paidInstallments: paid,
  dueDay: 10,
  firstMonth: october,
).valueOrNull!;

/// O cartão: fecha dia 25, vence dia 5 do mês seguinte.
final CreditCard nubank = CreditCard.create(
  id: 'nubank',
  name: 'Cartão Nubank',
  closingDay: 25,
  dueDay: 5,
).valueOrNull!;

/// Uma compra no cartão.
Entry onCard(int cents, {required LocalDate on, String id = 'card-1'}) => spend(
  cents,
  id: id,
  category: 'transport',
  on: on,
  line: PaymentLine(
    paymentMethodId: nubank.id,
    kind: PaymentMethodKind.creditCard,
    amount: Money.fromCents(cents),
  ),
);

/// A casa dos lembretes com [entries], o carnê e o plano.
Finances reminderFinances({
  List<Entry> entries = const [],
  List<Debt>? debts,
  int firstSalary = 180000,
}) => Finances(
  categories: householdCategories,
  plans: [reminderPlan(firstSalary: firstSalary)],
  entries: entries,
  debts: debts ?? [carneDebt()],
);

/// Os lembretes da casa em [today], com o cartão e [settlements].
List<DueReminder> remindersOf(
  Finances finances, {
  LocalDate? today,
  List<Settlement> settlements = const [],
}) => DueReminders.upcoming(
  finances,
  today: today ?? reminderToday,
  cards: [nubank],
  settlements: settlements,
);

/// Os lembretes do vencimento [eventKey].
List<DueReminder> ofEvent(List<DueReminder> reminders, String eventKey) => [
  for (final reminder in reminders)
    if (reminder.eventKey == eventKey) reminder,
];
