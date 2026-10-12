import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/statements/application/statement_matches.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final CreditCard _card = CreditCard.create(
  id: 'card-1',
  name: 'Cartão da casa',
  closingDay: 25,
  dueDay: 5,
).valueOrNull!;

/// Um gasto já lançado: [cents] no Pix, no dia [day] de setembro.
Entry _spent(String id, String description, int cents, int day) => Entry.create(
  id: id,
  description: description,
  amount: Money.fromCents(cents),
  occurredOn: LocalDate(2026, 9, day),
  category: DefaultCatalog.emptyBook.categoryOf('other'),
  paymentLines: [
    PaymentLine(
      paymentMethodId: 'pix',
      kind: PaymentMethodKind.pix,
      amount: Money.fromCents(cents),
    ),
  ],
  today: LocalDate(2026, 9, 30),
).valueOrNull!;

/// O fogão de R$ 960,00 em 6× no cartão, comprado em 19/08.
Entry _stove() {
  const total = Money.fromCents(96000);
  final bought = LocalDate(2026, 8, 19);
  return Entry.create(
    id: 'stove',
    description: 'Fogão Casa Bonita',
    amount: total,
    occurredOn: bought,
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
      purchasedOn: bought,
      principal: total,
      count: 6,
    ),
    today: bought,
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

/// A linha do extrato como o celular a escreveu, já resolvida.
ResolvedLine _line(String written, String description, int cents, int day) =>
    ResolvedLine(
      line: StatementLine(
        occurredOn: LocalDate(2026, 9, day),
        description: description,
        amount: Money.fromCents(cents),
      ),
      merchantKey: MerchantBrand.keyOf(description),
      installment: InstallmentMark.of(written),
    );

void main() {
  group('RN-1112 · o que já está no Cajui', () {
    test('duas compras iguais na padaria, uma lançada: a outra entra', () {
      final book = _book([_spent('pao', 'Padaria Boa Vista', 800, 2)]);
      final lines = [
        _line('02/09 PADARIA BOA VISTA 8,00', 'Padaria Boa Vista', 800, 2),
        _line('02/09 PADARIA BOA VISTA 8,00', 'Padaria Boa Vista', 800, 2),
      ];

      expect(StatementMatches.of(lines, book), {0});
    });

    test('o banco registra um ou dois dias depois: ainda é o mesmo', () {
      final book = _book([_spent('uber', 'Uber', 2500, 4)]);
      final lines = [_line('06/09 UBER *TRIP 25,00', 'Uber', 2500, 6)];

      expect(StatementMatches.of(lines, book), {0});
    });

    test('mesmo valor, outro nome: o Uber não esconde a farmácia', () {
      final book = _book([_spent('uber', 'Uber', 2500, 4)]);
      final lines = [
        _line('05/09 DROGARIA SAO JOAO 25,00', 'Drogaria São João', 2500, 5),
      ];

      expect(StatementMatches.of(lines, book), isEmpty);
    });

    test('a linha sem nome do lugar casa pelo valor e pelo dia', () {
      final book = _book([_spent('mercado', 'Mercado Boa Vista', 8000, 3)]);
      final lines = [_line('03/09 COMPRA NO DEBITO 80,00', 'Compra', 8000, 3)];

      expect(StatementMatches.of(lines, book), {0});
    });

    test('três dias de diferença já é outro gasto', () {
      final book = _book([_spent('uber', 'Uber', 2500, 4)]);
      final lines = [_line('07/09 UBER *TRIP 25,00', 'Uber', 2500, 7)];

      expect(StatementMatches.of(lines, book), isEmpty);
    });
  });

  group('RN-1111 · a parcela de uma compra que o cartão já conta', () {
    test('a 2ª de 6 do fogão já está lá, pelo plano', () {
      final book = _book([_stove()]);
      final lines = [
        _line('19/09 FOGAO CASA BONITA 2/6 160,00', 'Fogão', 16000, 19),
      ];

      expect(StatementMatches.of(lines, book), {0});
    });

    test('em outro número de vezes, é outra compra', () {
      final book = _book([_stove()]);
      final lines = [
        _line('19/09 FOGAO CASA BONITA 2/10 160,00', 'Fogão', 16000, 19),
      ];

      expect(StatementMatches.of(lines, book), isEmpty);
    });
  });
}
