import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

import 'test_scope.dart';

VariableBudget _budget(
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

FixedExpense _fixed(String id, String name, int cents, int day) => FixedExpense(
  id: id,
  name: name,
  amount: Money.fromCents(cents),
  dueDay: day,
  categoryId: 'rent',
  paymentMethodId: 'pix',
);

/// Um plano pequeno, com contas que dá para conferir de cabeça:
///
/// renda 3.200,00 · fixos 1.200,00 · dívidas 362,00 · transporte até 260,00 ·
/// mercado até 800,00, dos quais o vale (650,00) cobre 650,00 e sobram 150,00
/// em dinheiro. Variável em dinheiro: 410,00. Sobra planejada: 1.228,00.
/// Renda comprometida: 1.562,00 de 3.200,00 = 49%.
final MonthSetup samplePlan = MonthSetup(
  cashIncome: const Money.fromCents(320000),
  debtInstallments: const Money.fromCents(36200),
  fixedExpenses: [
    _fixed('f-rent', 'Aluguel', 110000, 10),
    _fixed('f-net', 'Internet', 10000, 15),
  ],
  variableBudgets: [
    _budget('groceries', 50000, 80000, voucher: true),
    _budget('transport', 18000, 26000),
  ],
);

/// Os fatos de quem já cadastrou [samplePlan] e tem 650,00 de vale.
final List<LedgerEvent> samplePlanEvents = [
  PlanDefined(id: 'plan-1', setup: samplePlan),
  VoucherBalanceAdjusted(
    id: 'voucher-1',
    adjustment: const Money.fromCents(65000),
    on: testToday,
    reason: 'saldo da operadora',
  ),
];
