import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

void main() {
  test('RN-1018 RN-209 · a compra devolvida na semana deixa de comer o '
      'limite, como já deixa de contar no mês', () {
    final ride = entry(
      id: 'uber',
      cents: 20000,
      lines: [pix(20000)],
      category: leisure,
      on: LocalDate(2026, 9, 28),
    );
    final back = Reversal.create(
      id: 'devolvido',
      entry: ride,
      paymentMethodId: 'pix',
      amount: const Money.fromCents(20000),
      occurredOn: LocalDate(2026, 9, 29),
    ).valueOrNull!;

    final week = WeekAllowance.of(
      limit: const Money.fromCents(50000),
      today: LocalDate(2026, 9, 30),
      entries: [ride],
      categories: {leisure.id: leisure},
      reversals: [back],
    );

    expect(week.spent, Money.zero);
    expect(week.left.cents, 50000);
  });
}
