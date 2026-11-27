import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

Entry _market(String id, int cents, int day) => entry(
  id: id,
  cents: cents,
  lines: [pix(cents)],
  on: LocalDate(2026, 9, day),
);

void main() {
  group('UnusualAmount.check', () {
    final history = [
      _market('a', 15000, 1),
      _market('b', 14000, 8),
      _market('c', 16000, 15),
    ];

    test('o zero a mais: R\$ 1.500,00 num mercado de R\$ 150,00 pede '
        'confirmação, com o normal de R\$ 150,00', () {
      final unusual = UnusualAmount.check(
        const Money.fromCents(150000),
        categoryId: 'groceries',
        history: history,
      );

      expect(unusual?.typical, const Money.fromCents(15000));
    });

    test('abaixo de dez vezes o normal passa sem pergunta', () {
      expect(
        UnusualAmount.check(
          const Money.fromCents(149999),
          categoryId: 'groceries',
          history: history,
        ),
        isNull,
      );
    });

    test('a mediana não se deixa puxar por uma compra grande do passado', () {
      // Com quatro, a mediana é a do meio de cima: R$ 160,00, e não a média
      // de R$ 2.362,50 que a compra grande faria.
      final withBigOne = [...history, _market('d', 900000, 20)];

      expect(
        UnusualAmount.check(
          const Money.fromCents(160000),
          categoryId: 'groceries',
          history: withBigOne,
        ),
        isNotNull,
      );
    });

    test('com menos de 3 lançamentos na categoria não há normal, e outra '
        'categoria não conta', () {
      expect(
        UnusualAmount.check(
          const Money.fromCents(150000),
          categoryId: 'groceries',
          history: history.take(2),
        ),
        isNull,
      );
      expect(
        UnusualAmount.check(
          const Money.fromCents(150000),
          categoryId: 'leisure',
          history: history,
        ),
        isNull,
      );
    });
  });
}
