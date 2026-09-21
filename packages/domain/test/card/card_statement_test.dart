import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// A fatura que vence em outubro: compras de 25/08 a 24/09.
final _cycle = StatementCycle.closingIn(card, const BudgetMonth(2026, 9));

/// Duas compras à vista no ciclo, uma parcela antiga e uma compra fora dele.
List<Entry> _entries() => [
  entry(id: 'a', cents: 44000, lines: [credit(44000)]),
  entry(
    id: 'b',
    cents: 20000,
    lines: [credit(20000)],
    category: internet,
    on: LocalDate(2026, 9, 3),
  ),
  parceled(id: 'sofa', cents: 90000, count: 6, on: LocalDate(2026, 8, 10)),
  entry(
    id: 'fora',
    cents: 9900,
    lines: [credit(9900)],
    on: LocalDate(2026, 8, 20),
  ),
  entry(id: 'pix', cents: 5000, lines: [pix(5000)]),
];

void main() {
  group('CardStatement', () {
    test('RN-330 soma à vista do ciclo e parcelas cobradas nele', () {
      final statement = CardStatement.of(_cycle, entries: _entries());

      // O sofá, comprado em 10/08, teve a 1ª parcela em setembro; esta
      // fatura cobra a 2ª.
      expect(statement.purchases, const Money.fromCents(64000));
      expect(statement.installments, const Money.fromCents(15000));
      expect(statement.total, const Money.fromCents(79000));
    });

    test('RN-330 desconta o estorno feito dentro do ciclo', () {
      final entries = _entries();
      final reversal = Reversal.create(
        id: 'r',
        entry: entries.first,
        paymentMethodId: 'card',
        amount: const Money.fromCents(4000),
        occurredOn: LocalDate(2026, 9, 15),
      ).valueOrNull!;

      final statement = CardStatement.of(
        _cycle,
        entries: entries,
        reversals: [reversal],
      );

      expect(statement.total, const Money.fromCents(75000));
    });

    test('RN-330 sem lançamentos no ciclo, a fatura é zero', () {
      expect(CardStatement.of(_cycle, entries: const []).total, Money.zero);
    });

    test('RN-331 dá a composição por categoria', () {
      final statement = CardStatement.of(_cycle, entries: _entries());

      expect(statement.purchasesByCategory, {
        'groceries': const Money.fromCents(44000),
        'internet': const Money.fromCents(20000),
      });
    });

    test('RN-332 a diferença para a fatura do banco fica "não identificada"', () {
      final statement = CardStatement.of(_cycle, entries: _entries());

      expect(
        statement.unidentifiedGiven(const Money.fromCents(85000)),
        const Money.fromCents(6000),
      );
    });

    test('soma as parcelas de compras anteriores ao uso do app', () {
      final statement = CardStatement.of(
        _cycle,
        entries: const [],
        legacyInstallments: const Money.fromCents(15000),
      );

      expect(statement.total, const Money.fromCents(15000));
    });
  });

  group('StatementReserve', () {
    test('RN-320 é o que foi comprado à vista e ainda não foi liquidado', () {
      final reserve = StatementReserve.of(card, entries: _entries());

      // 440,00 + 200,00 do ciclo de outubro + 99,00 do ciclo de setembro.
      expect(reserve, const Money.fromCents(73900));
    });

    test('RN-341 liquidar a fatura tira o ciclo da reserva', () {
      final settlement = Settlement(
        id: 's',
        cardId: 'card',
        dueMonth: const BudgetMonth(2026, 9),
        amount: const Money.fromCents(9900),
        paidOn: LocalDate(2026, 9, 5),
      );

      final reserve = StatementReserve.of(
        card,
        entries: _entries(),
        settlements: [settlement],
      );

      expect(reserve, const Money.fromCents(64000));
    });
  });

  group('Settlement', () {
    Settlement paying(int cents) => Settlement(
      id: 's',
      cardId: 'card',
      dueMonth: const BudgetMonth(2026, 10),
      amount: Money.fromCents(cents),
      paidOn: LocalDate(2026, 10, 5),
    );
    const statementTotal = Money.fromCents(124000);

    test('RN-342 pagamento menor deixa saldo em aberto, que vira dívida', () {
      final partial = paying(40000);

      expect(
        partial.openBalanceFor(statementTotal),
        const Money.fromCents(84000),
      );
      expect(partial.overpaidFor(statementTotal), Money.zero);
    });

    test('RN-344 pagamento maior é aceito, e a diferença é apontada', () {
      final over = paying(124000);

      expect(
        over.overpaidFor(const Money.fromCents(118000)),
        const Money.fromCents(6000),
      );
      expect(over.openBalanceFor(const Money.fromCents(118000)), Money.zero);
    });

    test('RN-340 pagar a fatura não é lançamento: não há Entry envolvida', () {
      // A liquidação é um tipo próprio, sem categoria e sem bloco. O teste
      // existe para que a regra tenha um lugar onde quebrar, se alguém um dia
      // der a `Settlement` uma categoria.
      expect(paying(124000), isNot(isA<Entry>()));
    });
  });
}
