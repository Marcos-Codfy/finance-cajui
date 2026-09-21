import 'package:domain/domain.dart';

/// Peças prontas para os testes do domínio, com os nomes e valores do cenário
/// único da especificação (setembro de 2026).

/// O dia em que os testes "acontecem".
final LocalDate today = LocalDate(2026, 9, 20);

/// Categoria do bloco variável, elegível ao vale.
const Category groceries = Category(
  id: 'groceries',
  name: 'Mercado',
  block: Block.variable,
  groupId: 'food',
  voucherEligible: true,
);

/// Categoria do bloco fixo, que o vale não paga.
const Category internet = Category(
  id: 'internet',
  name: 'Internet',
  block: Block.fixed,
  groupId: 'housing',
);

/// Categoria variável, que o vale não paga.
const Category leisure = Category(
  id: 'leisure',
  name: 'Lazer',
  block: Block.variable,
  groupId: 'leisure',
);

/// Uma linha paga no Pix.
PaymentLine pix(int cents) => PaymentLine(
  paymentMethodId: 'pix',
  kind: PaymentMethodKind.pix,
  amount: Money.fromCents(cents),
);

/// Uma linha paga no vale alimentação.
PaymentLine voucher(int cents) => PaymentLine(
  paymentMethodId: 'voucher',
  kind: PaymentMethodKind.mealVoucher,
  amount: Money.fromCents(cents),
);

/// Uma linha paga no cartão de crédito [cardId].
PaymentLine credit(int cents, {String cardId = 'card'}) => PaymentLine(
  paymentMethodId: cardId,
  kind: PaymentMethodKind.creditCard,
  amount: Money.fromCents(cents),
);

/// Tenta criar um lançamento; devolve o resultado, para o teste olhar os dois
/// casos.
Result<Entry> tryEntry({
  required int cents,
  required List<PaymentLine> lines,
  Category category = groceries,
  LocalDate? on,
  String id = 'e1',
  String description = 'Mercado Boa Compra',
  bool isExceptional = false,
  InstallmentPlan? plan,
}) => Entry.create(
  id: id,
  description: description,
  amount: Money.fromCents(cents),
  occurredOn: on ?? LocalDate(2026, 9, 12),
  category: category,
  paymentLines: lines,
  today: today,
  isExceptional: isExceptional,
  installmentPlan: plan,
);

/// Cria um lançamento que o teste sabe ser válido.
Entry entry({
  required int cents,
  required List<PaymentLine> lines,
  Category category = groceries,
  LocalDate? on,
  String id = 'e1',
  String description = 'Mercado Boa Compra',
  bool isExceptional = false,
  InstallmentPlan? plan,
}) => tryEntry(
  cents: cents,
  lines: lines,
  category: category,
  on: on,
  id: id,
  description: description,
  isExceptional: isExceptional,
  plan: plan,
).valueOrNull!;

/// O cartão do cenário: fecha dia 25, vence dia 5 do mês seguinte.
final CreditCard card = CreditCard.create(
  id: 'card',
  name: 'Cartão roxo',
  closingDay: 25,
  dueDay: 5,
).valueOrNull!;

/// Uma compra parcelada no cartão [card], em [count] vezes.
Entry parceled({
  required String id,
  required int cents,
  required int count,
  required LocalDate on,
  Category category = leisure,
  int? installmentCents,
  CreditCard? onCard,
}) {
  final used = onCard ?? card;
  return entry(
    id: id,
    cents: cents,
    lines: [credit(cents, cardId: used.id)],
    category: category,
    on: on,
    plan: InstallmentPlan.forPurchase(
      card: used,
      purchasedOn: on,
      principal: Money.fromCents(cents),
      count: count,
      installmentAmount: installmentCents == null
          ? null
          : Money.fromCents(installmentCents),
    ),
  );
}
