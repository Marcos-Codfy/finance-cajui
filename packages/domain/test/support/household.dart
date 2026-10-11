import 'package:domain/domain.dart';

/// Uma casa inventada, com a estrutura da planilha do dono e números que
/// não são os dele: dois salários, vale, dízimo de 10%, contas fixas,
/// assinaturas, dia a dia e um carnê.

/// O dia em que os testes acontecem.
final LocalDate householdToday = LocalDate(2026, 10, 20);

/// Outubro de 2026.
const BudgetMonth october = BudgetMonth(2026, 10);

Category _category(String id, String name, Block block, {bool food = false}) =>
    Category(
      id: id,
      name: name,
      block: block,
      groupId: id,
      voucherEligible: food,
    );

/// As categorias da casa.
final Map<String, Category> householdCategories = {
  for (final category in [
    _category('rent', 'Aluguel', Block.fixed),
    _category('utilities', 'Água, luz e internet', Block.fixed),
    _category('subscriptions', 'Assinaturas', Block.subscription),
    _category('transport', 'Transporte', Block.variable),
    _category('groceries', 'Mercado', Block.variable, food: true),
    _category('health', 'Farmácia', Block.variable),
    _category('interest-and-fees', 'Juros e tarifas', Block.debt),
  ])
    category.id: category,
};

BudgetLine _line(String id, int cents, LineGroup group, String category) =>
    BudgetLine.create(
      id: id,
      name: id,
      amount: Money.fromCents(cents),
      group: group,
      categoryId: category,
    ).valueOrNull!;

/// Um salário.
IncomeSource salary(String id, int cents) => IncomeSource(
  id: id,
  name: id,
  tender: Tender.cash,
  expectedAmount: Money.fromCents(cents),
  expectedDay: 5,
);

/// O plano da casa: R$ 3.300 de salários, R$ 500 de vale, dízimo de 10%.
BudgetPlan householdPlan({
  int firstSalary = 180000,
  int titheBasisPoints = 1000,
  DateTime? definedAt,
}) => BudgetPlan(
  salaries: [salary('salary-a', firstSalary), salary('salary-b', 150000)],
  voucher: const Money.fromCents(50000),
  titheBasisPoints: titheBasisPoints,
  definedAt: definedAt,
  lines: [
    _line('Aluguel', 100000, LineGroup.fixedBill, 'rent'),
    _line('Energia', 18000, LineGroup.fixedBill, 'utilities'),
    _line('Internet', 9000, LineGroup.fixedBill, 'utilities'),
    _line('Streaming', 4000, LineGroup.subscription, 'subscriptions'),
    _line('Música', 2000, LineGroup.subscription, 'subscriptions'),
    _line('Transporte', 40000, LineGroup.dayToDay, 'transport'),
    _line('Mercado', 60000, LineGroup.dayToDay, 'groceries'),
    _line('Farmácia', 10000, LineGroup.dayToDay, 'health'),
  ],
);

/// O carnê: R$ 120 por mês, 10 parcelas a partir de outubro, dia 10.
final Debt carne = Debt.create(
  id: 'carne',
  creditor: 'Carnê da loja',
  kind: DebtKind.informal,
  installmentAmount: const Money.fromCents(12000),
  totalInstallments: 10,
  paidInstallments: 0,
  dueDay: 10,
  firstMonth: october,
).valueOrNull!;

/// Um lançamento, criado com um "hoje" que aceita outubro inteiro.
Entry spend(
  int cents, {
  required String category,
  required LocalDate on,
  String id = 'e1',
  PaymentLine? line,
}) => Entry.create(
  id: id,
  description: 'Compra $id',
  amount: Money.fromCents(cents),
  occurredOn: on,
  category: householdCategories[category]!,
  paymentLines: [
    line ??
        PaymentLine(
          paymentMethodId: 'pix',
          kind: PaymentMethodKind.pix,
          amount: Money.fromCents(cents),
        ),
  ],
  today: LocalDate(2026, 12, 31),
).valueOrNull!;

/// A casa com [entries] e [receipts], e o plano e o carnê de sempre.
Finances household({
  List<Entry> entries = const [],
  List<IncomeReceipt> receipts = const [],
  List<BudgetPlan>? plans,
  Set<String> excluded = const {},
}) => Finances(
  categories: householdCategories,
  plans: plans ?? [householdPlan()],
  entries: entries,
  receipts: receipts,
  debts: [carne],
  excluded: excluded,
);
