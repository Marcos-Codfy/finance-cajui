import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final _bought = LocalDate(2026, 9, 19);
const _september = BudgetMonth(2026, 9);
const _october = BudgetMonth(2026, 10);

final CreditCard _card = CreditCard.create(
  id: 'card-1',
  name: 'Cartão da casa',
  closingDay: 25,
  dueDay: 5,
).valueOrNull!;

/// O fogão do exemplo da RN-311: R$ 960,00 em 6×, comprado em 19/09 no
/// cartão que fecha dia 25.
Entry _stove() {
  const total = Money.fromCents(96000);
  return Entry.create(
    id: 'stove',
    description: 'Fogão',
    amount: total,
    occurredOn: _bought,
    category: DefaultCatalog.emptyBook.categoryOf('home'),
    paymentLines: [
      PaymentLine(
        paymentMethodId: _card.id,
        kind: PaymentMethodKind.creditCard,
        amount: total,
      ),
    ],
    installmentPlan: InstallmentPlan.forPurchase(
      card: _card,
      purchasedOn: _bought,
      principal: total,
      count: 6,
    ),
    today: _bought,
  ).valueOrNull!;
}

LedgerBook _book(List<Entry> entries) {
  final base = DefaultCatalog.emptyBook;
  return LedgerBook(
    categories: base.categories,
    paymentMethods: base.paymentMethods,
    cards: [_card],
    entries: entries,
  );
}

void main() {
  group('RN-311 · a compra parcelada não conta no mês da compra', () {
    test('setembro não muda por causa do fogão de 6×', () {
      // O livro somava `paidByTender` e punha os R$ 960,00 inteiros em
      // setembro — no painel, nos resumos, no assistente e no fechamento.
      // Quem decide o que conta é o domínio.
      final book = _book([_stove()]);

      expect(book.spentIn(_september), TenderAmounts.zero);
      expect(book.spentIn(_october), TenderAmounts.zero);
    });

    test('mas ela entra no mês como compromisso do bloco de dívidas', () {
      // RN-312: a parcela conta, uma por mês, e a primeira é a de outubro.
      final book = _book([_stove()]);

      expect(book.installmentsDueIn(_september), Money.zero);
      expect(book.installmentsDueIn(_october), const Money.fromCents(16000));
    });

    test('compra à vista no cartão continua contando no mês da compra', () {
      // RN-310: o dinheiro só sai na fatura, mas o gasto é de setembro.
      const cash = Money.fromCents(5000);
      final entry = Entry.create(
        id: 'lunch',
        description: 'Almoço',
        amount: cash,
        occurredOn: _bought,
        category: DefaultCatalog.emptyBook.categoryOf('home'),
        paymentLines: [
          PaymentLine(
            paymentMethodId: _card.id,
            kind: PaymentMethodKind.creditCard,
            amount: cash,
          ),
        ],
        today: _bought,
      ).valueOrNull!;

      expect(_book([entry]).spentIn(_september).cash, cash);
    });
  });
}
