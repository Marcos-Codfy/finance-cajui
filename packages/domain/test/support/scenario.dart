import 'package:domain/domain.dart';

/// O exemplo completo de `docs/spec/rules/indicators.md`: setembro de 2026.
///
/// Renda em dinheiro de R$ 3.200, vale de R$ 650, fixos de R$ 1.300, dívidas
/// de R$ 362 e variáveis de R$ 980 em dinheiro — sobra planejada de R$ 558.
/// Os testes do domínio conferem os números contra este cenário, que é o
/// mesmo da especificação e o mesmo da gallery.

/// Setembro de 2026.
const BudgetMonth september = BudgetMonth(2026, 9);

FixedExpense _fixed(String id, String name, int cents, int day) =>
    FixedExpense(
      id: id,
      name: name,
      amount: Money.fromCents(cents),
      dueDay: day,
      categoryId: id,
      paymentMethodId: 'pix',
    );

/// Aluguel, internet, streaming e celular: R$ 1.300.
final List<FixedExpense> fixedExpenses = [
  _fixed('rent', 'Aluguel', 110000, 10),
  _fixed('internet', 'Internet', 10000, 15),
  _fixed('streaming', 'Streaming', 4000, 20),
  _fixed('mobile', 'Celular', 6000, 25),
];

VariableBudget _variable(
  String category,
  int min,
  int max, {
  bool voucher = false,
}) => VariableBudget(
  categoryId: category,
  range: AmountRange.create(
    min: Money.fromCents(min),
    max: Money.fromCents(max),
  ).valueOrNull!,
  voucherEligible: voucher,
);

/// Mercado (elegível ao vale), transporte, lazer, farmácia e luz.
final List<VariableBudget> variableBudgets = [
  _variable('groceries', 50000, 80000, voucher: true),
  _variable('transport', 18000, 26000),
  _variable('leisure', 10000, 25000),
  _variable('pharmacy', 5000, 15000),
  _variable('power', 11000, 17000),
];

/// O plano de setembro, como no exemplo.
MonthPlan septemberPlan({
  Map<String, Money> paidFixed = const {},
  BudgetMonth month = september,
}) => MonthPlan.of(
  month: month,
  cashIncome: const Money.fromCents(320000),
  voucherAvailable: const Money.fromCents(65000),
  fixedExpenses: fixedExpenses,
  variableBudgets: variableBudgets,
  debtInstallments: const Money.fromCents(36200),
  paidFixed: paidFixed,
);
