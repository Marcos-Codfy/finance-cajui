import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/scenario.dart';

/// O exemplo completo de `docs/spec/rules/indicators.md`, número por número.
/// Se este arquivo passa, o domínio e a especificação dizem a mesma coisa.

Money _cents(int cents) => Money.fromCents(cents);

Category _variable(String id) =>
    Category(id: id, name: id, block: Block.variable, groupId: id);

final Map<String, Category> _categories = {
  for (final id in ['transport', 'leisure', 'pharmacy', 'power', 'repairs'])
    id: _variable(id),
  'groceries': groceries,
  'internet': internet,
};

Entry _spend(String id, int cents, int day, {String category = 'leisure'}) =>
    entry(
      id: id,
      cents: cents,
      lines: [pix(cents)],
      category: _categories[category]!,
      on: LocalDate(2026, 9, day),
    );

/// O gasto de rotina do exemplo: 170, 260, 200 e 230 nas quatro primeiras
/// semanas.
final List<Entry> _routine = [
  _spend('w1', 17000, 3),
  _spend('w2', 26000, 9, category: 'transport'),
  _spend('w3', 20000, 16),
  _spend('w4', 23000, 23, category: 'transport'),
];

MonthSpending _spending(List<Entry> entries) =>
    MonthSpending.of(september, entries: entries, categories: _categories);

WeeklyLimit _limitOn(int day, List<Entry> entries) => WeeklyLimit.of(
  week: BudgetWeek.containing(LocalDate(2026, 9, day)),
  variableBudget: septemberPlan().variableCash,
  spending: _spending(entries),
);

void main() {
  final planned = MonthIndicators(septemberPlan(), _spending(const []));

  group('sobra, comprometimento e custo por dia', () {
    test('RN-620 resultado planejado: 3.200 − 1.300 − 362 − 980 = 558', () {
      expect(planned.plannedResult, _cents(55800));
    });

    test('RN-630 e RN-632 comprometimento total: 1.662 ÷ 3.200 → 52%', () {
      expect(planned.commitmentPercent, 52);
    });

    test('RN-631 comprometimento por grupo, em percentual inteiro', () {
      expect(planned.percentOfIncome(_cents(127000)), 40); // moradia
      expect(planned.percentOfIncome(_cents(26000)), 8); // transporte
      expect(planned.percentOfIncome(_cents(20000)), 6); // assinaturas
      expect(planned.percentOfIncome(_cents(36200)), 11); // dívidas
    });

    test('RN-650 e RN-605 custo por dia, um número por moeda', () {
      expect(planned.plannedDailyCost.cash, _cents(8807));
      expect(planned.plannedDailyCost.mealVoucher, _cents(2167));
    });

    test('RN-604 sem renda em dinheiro, a proporção é indefinida', () {
      final noIncome = MonthIndicators(
        MonthPlan.of(
          month: september,
          cashIncome: Money.zero,
          voucherAvailable: Money.zero,
          fixedExpenses: fixedExpenses,
          variableBudgets: const [],
          debtInstallments: Money.zero,
        ),
        _spending(const []),
      );

      expect(noIncome.commitmentPercent, isNull);
    });
  });

  group('limite semanal', () {
    test('RN-644 as semanas são de calendário, recortadas pelo mês', () {
      final first = BudgetWeek.containing(LocalDate(2026, 9, 1));
      final last = BudgetWeek.containing(LocalDate(2026, 9, 29));

      // Setembro de 2026 começa numa terça: a 1ª semana tem 6 dias.
      expect((first.start.day, first.end.day, first.days), (1, 6, 6));
      expect((last.start.day, last.end.day, last.days), (28, 30, 3));
      expect(last.next, isNull);
      expect(first.next!.start, LocalDate(2026, 9, 7));
    });

    test('RN-641 os cinco limites do exemplo, centavo a centavo', () {
      final limits = [
        for (final day in [1, 7, 14, 21, 28]) _limitOn(day, _routine).limit,
      ];

      expect(limits.map((limit) => limit.cents), [
        19600,
        23625,
        22647,
        24500,
        12000,
      ]);
    });

    test('RN-642 passar do limite aparece como valor, sem bloquear nada', () {
      final secondWeek = _limitOn(9, _routine);

      expect(secondWeek.spent, _cents(26000));
      expect(secondWeek.remaining, _cents(-2375));
    });

    test('RN-643 vale, fixo, parcela e outro mês não contam na semana', () {
      final entries = [
        ..._routine,
        entry(id: 'vale', cents: 9000, lines: [voucher(9000)]),
        entry(
          id: 'fixo',
          cents: 10000,
          lines: [pix(10000)],
          category: internet,
          on: LocalDate(2026, 9, 9),
        ),
        parceled(
          id: 'fogao',
          cents: 96000,
          count: 6,
          on: LocalDate(2026, 9, 9),
        ),
      ];

      expect(_limitOn(9, entries).spent, _cents(26000));
    });

    test('RN-310 compra à vista no cartão reduz a semana da compra', () {
      final entries = [
        ..._routine,
        entry(id: 'mercado', cents: 18640, lines: [credit(18640)]),
      ];

      expect(_limitOn(12, entries).spent, _cents(26000 + 18640));
    });

    test('RN-646 lançamento tardio de semana passada recalcula esta', () {
      final late = [..._routine, _spend('tardio', 5000, 8)];

      // restante 550 − 50 = 500; 500 × 7 ÷ 17 = 205,88
      expect(_limitOn(14, late).limit, _cents(20588));
    });

    test('RN-645 variável esgotado: limite zero, e quanto passou do plano', () {
      final spentAll = [..._routine, _spend('extra', 16000, 17)];

      final lastWeek = _limitOn(28, spentAll);

      // 980 − 170 − 260 − 200 − 160 − 230 = −40
      expect(lastWeek.limit, Money.zero);
      expect(lastWeek.monthOverrun, _cents(4000));
    });
  });

  group('quanto falta ajustar', () {
    final repair = entry(
      id: 'conserto',
      cents: 70000,
      lines: [pix(70000)],
      category: _categories['repairs']!,
      on: LocalDate(2026, 9, 3),
      isExceptional: true,
    );
    final withRepair = MonthIndicators(septemberPlan(), _spending([repair]));

    test('RN-621 e RN-648 o fora do padrão conta inteiro no resultado', () {
      expect(withRepair.projectedResult, _cents(-14200));
    });

    test('RN-648 mas fica fora do limite da semana', () {
      final week = _limitOn(3, [repair]);

      expect(week.limit, _cents(19600));
      expect(week.spent, Money.zero);
    });

    test('RN-660 a 662 ajuste de 142 cabe na folga de 540', () {
      expect(withRepair.requiredAdjustment, _cents(14200));
      expect(withRepair.adjustableSlack, _cents(54000));
      expect(withRepair.closesByAdjustingVariables, isTrue);
    });

    test('RN-662 as opções vêm do maior corte para o menor', () {
      final options = withRepair.adjustmentOptions
          .map((line) => line.budget.categoryId)
          .toList();

      expect(options.first, anyOf('groceries', 'leisure'));
      expect(options.last, 'power');
    });

    test('RN-661 o que já foi gasto na categoria reduz a folga dela', () {
      // Lazer 100–250, com 170 gastos: dá para cortar só até 170.
      final spent = MonthIndicators(septemberPlan(), _spending([_routine[0]]));

      expect(spent.slackOf(septemberPlan().variables[2]), _cents(8000));
    });

    test('RN-424 gasto em categoria sem faixa conta inteiro além do plano', () {
      final offPlan = _spend('sem-faixa', 7000, 5, category: 'repairs');
      final indicators = MonthIndicators(septemberPlan(), _spending([offPlan]));

      expect(indicators.projectedResult, _cents(55800 - 7000));
    });

    test('RN-423 passar do máximo é aceito, e a projeção usa o real', () {
      final overspent = _spend('lazer', 31000, 5);
      final indicators = MonthIndicators(
        septemberPlan(),
        _spending([overspent]),
      );

      // Lazer máximo 250, gasto 310: o mês projeta 60 a menos.
      expect(indicators.projectedResult, _cents(55800 - 6000));
    });

    test('E-BUDG-03 o corte não leva a categoria abaixo do mínimo', () {
      final leisureBudget = variableBudgets[2];

      expect(
        BudgetAdjustment.maxAfterCut(leisureBudget, _cents(15000)).valueOrNull,
        _cents(10000),
      );
      expect(
        BudgetAdjustment.maxAfterCut(
          leisureBudget,
          _cents(15001),
        ).failureOrNull,
        isA<AdjustmentBelowMinimum>(),
      );
    });
  });

  group('estorno', () {
    test('RN-209 reduz o gasto da categoria no mês do estorno', () {
      final purchase = _spend('compra', 12000, 5);
      final refund = Reversal.create(
        id: 'r',
        entry: purchase,
        paymentMethodId: 'pix',
        amount: _cents(12000),
        occurredOn: LocalDate(2026, 9, 20),
      ).valueOrNull!;

      final spending = MonthSpending.of(
        september,
        entries: [purchase],
        categories: _categories,
        reversals: [refund],
      );

      expect(spending.routineByCategory['leisure'], Money.zero);
      expect(spending.routineBefore(LocalDate(2026, 9, 14)), _cents(12000));
    });
  });
}
