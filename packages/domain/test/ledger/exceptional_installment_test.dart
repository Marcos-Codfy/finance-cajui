import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _march = BudgetMonth(2026, 3);

/// A TV: R$ 3.000,00 em 10×, marcada fora do padrão, comprada em 10/03.
Entry _tv() => entry(
  id: 'tv',
  cents: 300000,
  lines: [credit(300000)],
  category: leisure,
  on: LocalDate(2026, 3, 10),
  isExceptional: true,
  plan: InstallmentPlan.forPurchase(
    card: card,
    purchasedOn: LocalDate(2026, 3, 10),
    principal: const Money.fromCents(300000),
    count: 10,
  ),
);

/// O conserto: R$ 700,00 à vista no Pix, fora do padrão, em 03/03.
Entry _repair() => entry(
  id: 'conserto',
  cents: 70000,
  lines: [pix(70000)],
  category: leisure,
  on: LocalDate(2026, 3, 3),
  isExceptional: true,
);

void main() {
  group('Fora do padrão em compra parcelada', () {
    test('RN-242 o acumulado do ano leva o valor da compra, inteiro, no mês '
        'em que foi feita', () {
      final year = ExceptionalSpending.of([_tv(), _repair()], upTo: _march);

      expect(year.count, 2);
      expect(year.total, const Money.fromCents(370000));
    });

    test('RN-242 o resultado do mês não leva a compra parcelada: ela conta '
        'parcela a parcela, em dívidas (RN-312)', () {
      final month = MonthSpending.of(
        _march,
        entries: [_tv(), _repair()],
        categories: {leisure.id: leisure},
      );

      expect(month.exceptional, const Money.fromCents(70000));
    });

    test('RN-242 a parcela do mês é a que pesa, e nunca junto com o valor '
        'cheio da compra', () {
      final tv = _tv();

      expect(tv.spentIn(_march).cash, Money.zero);
      expect(
        tv.installmentPlan!
            .installmentDueIn(const BudgetMonth(2026, 4))
            ?.amount,
        const Money.fromCents(30000),
      );
      expect(tv.installmentPlan!.total, const Money.fromCents(300000));
    });
  });
}
