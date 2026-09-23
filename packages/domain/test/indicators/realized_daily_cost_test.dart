import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/scenario.dart';

/// O custo de vida por dia **realizado** (RN-651), sobre o mesmo setembro do
/// exemplo da especificação.

Money _cents(int cents) => Money.fromCents(cents);

void main() {
  final planned = MonthIndicators(
    septemberPlan(),
    MonthSpending.of(september, entries: const [], categories: const {}),
  );

  group('custo de vida por dia realizado', () {
    test('RN-651 e RN-652 custo por dia realizado: o que já saiu dividido '
        'pelos dias decorridos, contando hoje', () {
      // As quatro semanas do exemplo somam R$ 870,00 em dinheiro, e o vale
      // pagou R$ 300,00. No dia 25 são 25 dias decorridos.
      final gasto = TenderAmounts(
        cash: _cents(87000),
        mealVoucher: _cents(30000),
      );

      final porDia = planned.realizedDailyCost(
        gasto,
        today: LocalDate(2026, 9, 25),
      );

      expect(porDia.cash, _cents(3480)); // 87000 ÷ 25
      expect(porDia.mealVoucher, _cents(1200)); // 30000 ÷ 25
    });

    test('RN-651 mês já fechado conta os dias todos, e mês por vir não tem '
        'dia decorrido nenhum', () {
      final gasto = TenderAmounts(cash: _cents(87000));

      final depois = planned.realizedDailyCost(
        gasto,
        today: LocalDate(2026, 11, 4),
      );
      final antes = planned.realizedDailyCost(
        gasto,
        today: LocalDate(2026, 8, 30),
      );

      expect(depois.cash, _cents(2900)); // 87000 ÷ 30
      expect(antes, TenderAmounts.zero, reason: 'nada de divisão por zero');
    });
  });
}
