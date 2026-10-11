import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _salary = IncomeSource(
  id: 'salary',
  name: 'Salário',
  tender: Tender.cash,
  expectedAmount: Money.fromCents(240000),
  expectedDay: 5,
);

void main() {
  group('RN-758 · o recebimento parece a renda do plano', () {
    test(r'o exemplo da regra: R$ 2.310 em 05/09 parece o salário de R$ 2.400 '
        r'do dia 5; R$ 150 não parece', () {
      expect(
        _salary.looksLike(const Money.fromCents(231000), LocalDate(2026, 9, 5)),
        isTrue,
      );
      expect(
        _salary.looksLike(const Money.fromCents(15000), LocalDate(2026, 9, 5)),
        isFalse,
      );
    });

    test('valor perto, mas dia longe, não parece', () {
      expect(
        _salary.looksLike(
          const Money.fromCents(240000),
          LocalDate(2026, 9, 15),
        ),
        isFalse,
      );
    });

    test('o salário do dia 1 que cai no dia 30 do mês anterior está a dois '
        'dias, e não a vinte e nove', () {
      const firstDay = IncomeSource(
        id: 'salary',
        name: 'Salário',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(240000),
        expectedDay: 1,
      );

      expect(
        firstDay.looksLike(
          const Money.fromCents(240000),
          LocalDate(2026, 9, 30),
        ),
        isTrue,
      );
    });

    test('fonte desativada não parece nada (RN-134)', () {
      const ended = IncomeSource(
        id: 'salary',
        name: 'Salário',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(240000),
        expectedDay: 5,
        inactiveFrom: BudgetMonth(2026, 9),
      );

      expect(
        ended.looksLike(const Money.fromCents(240000), LocalDate(2026, 9, 5)),
        isFalse,
      );
    });
  });

  group('RN-707 · a linha do extrato que parece já lançada', () {
    final recorded = entry(
      cents: 1500,
      lines: [pix(1500)],
      on: LocalDate(2026, 9, 3),
      description: 'Padaria Central',
    );

    test('mesmo valor, com a data a até dois dias, avisa — o banco escreve o '
        'nome do jeito dele', () {
      expect(
        PossibleDuplicate.near(
          [recorded],
          amount: const Money.fromCents(1500),
          occurredOn: LocalDate(2026, 9, 5),
        ),
        recorded,
      );
    });

    test('valor diferente, ou data longe, não avisa', () {
      expect(
        PossibleDuplicate.near(
          [recorded],
          amount: const Money.fromCents(1600),
          occurredOn: LocalDate(2026, 9, 3),
        ),
        isNull,
      );
      expect(
        PossibleDuplicate.near(
          [recorded],
          amount: const Money.fromCents(1500),
          occurredOn: LocalDate(2026, 9, 9),
        ),
        isNull,
      );
    });
  });
}
