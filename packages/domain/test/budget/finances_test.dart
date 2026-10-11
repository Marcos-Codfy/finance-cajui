import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';

Money _brl(num reais) => Money.fromCents((reais * 100).round());

PaymentLine _card(int cents, {String cardId = 'nubank'}) => PaymentLine(
  paymentMethodId: cardId,
  kind: PaymentMethodKind.creditCard,
  amount: Money.fromCents(cents),
);

CreditCard _cardWithLimit(int? cents) => CreditCard.create(
  id: 'nubank',
  name: 'Cartão Nubank',
  closingDay: 25,
  dueDay: 5,
  creditLimit: cents == null ? null : Money.fromCents(cents),
).valueOrNull!;

void main() {
  group('RN-1020 · o cartão no mês', () {
    test('usado, sobra e os avisos de 50% e 80%, pelos centavos', () {
      CardMonthUsage usage(int cents) => CardMonthUsage.of(
        _cardWithLimit(100000),
        october,
        entries: [
          spend(
            cents,
            category: 'transport',
            on: LocalDate(2026, 10, 3),
            line: _card(cents),
          ),
        ],
      )!;

      expect(usage(49999).alert, CardUsageAlert.none);
      expect(usage(50000).alert, CardUsageAlert.half);
      expect(usage(79999).alert, CardUsageAlert.half);
      expect(usage(80000).alert, CardUsageAlert.high);
      expect(usage(30000).left, _brl(700));
      expect(usage(30000).percent, 30);
    });

    test('compra de outro mês e de outro cartão não contam; sem limite, não '
        'há uso', () {
      final entries = [
        spend(
          20000,
          category: 'transport',
          on: LocalDate(2026, 9, 30),
          line: _card(20000),
        ),
        spend(
          30000,
          id: 'e2',
          category: 'transport',
          on: LocalDate(2026, 10, 1),
          line: _card(30000, cardId: 'outro'),
        ),
      ];

      expect(
        CardMonthUsage.of(
          _cardWithLimit(100000),
          october,
          entries: entries,
        )!.used,
        Money.zero,
      );
      expect(
        CardMonthUsage.of(_cardWithLimit(null), october, entries: entries),
        isNull,
      );
    });
  });

  group('RN-1040 · o mês a mês, sem botão de fechar', () {
    test(
      'entrou, saiu, sobrou e quanto ainda devo, do primeiro mês até agora',
      () {
        final finances = household(
          entries: [
            spend(70000, category: 'groceries', on: LocalDate(2026, 9, 10)),
            spend(
              15000,
              id: 'e2',
              category: 'transport',
              on: LocalDate(2026, 10, 3),
            ),
          ],
        );

        final history = finances.history(october);

        expect(history.map((record) => record.month), [
          october,
          const BudgetMonth(2026, 9),
        ]);
        final october_ = history.first;
        expect(october_.cameIn, _brl(3300));
        expect(october_.wentOut, _brl(2380));
        expect(october_.leftOver, _brl(920));
        expect(october_.stillOwed, _brl(1080));
      },
    );

    test('um lançamento atrasado muda o mês dele sozinho', () {
      final before = household().recordOf(october).wentOut;
      final after = household(
        entries: [
          spend(90000, category: 'groceries', on: LocalDate(2026, 10, 2)),
        ],
      ).recordOf(october).wentOut;

      expect(after - before, _brl(300));
    });

    test('cada mês usa o plano que valia nele', () {
      final finances = household(
        plans: [
          householdPlan(definedAt: DateTime.utc(2026, 9, 15)),
          householdPlan(
            firstSalary: 200000,
            definedAt: DateTime.utc(2026, 10, 20),
          ),
        ],
      );

      expect(finances.cashIncomeIn(const BudgetMonth(2026, 8)), _brl(3300));
      expect(finances.cashIncomeIn(const BudgetMonth(2026, 9)), _brl(3300));
      expect(finances.cashIncomeIn(october), _brl(3500));
      expect(finances.plan.salaries.first.expectedAmount, _brl(2000));
    });
  });

  group('RN-1050 · o plano não é obrigatório', () {
    Finances withoutPlan(LocalDate firstDay) => Finances(
      categories: householdCategories,
      plans: const [],
      entries: [
        spend(52340, category: 'groceries', on: LocalDate(2026, 10, 10)),
        spend(1000, id: 'e2', category: 'transport', on: firstDay),
        spend(
          3000,
          id: 'e3',
          category: 'interest-and-fees',
          on: LocalDate(2026, 10, 11),
        ),
      ],
    );

    test('depois de um mês de uso, sugere as contas pelo que foi gasto, '
        'arredondando para cima', () {
      final suggestion = withoutPlan(LocalDate(2026, 9, 1))
          .suggestion(householdToday)!;

      expect(suggestion.lines.first.name, 'Mercado');
      expect(suggestion.lines.first.amount, _brl(530));
      expect(suggestion.lines.first.group, LineGroup.dayToDay);
      expect(
        suggestion.lines.map((line) => line.categoryId),
        isNot(contains('interest-and-fees')),
      );
    });

    test('com menos de um mês de uso, não sugere nada', () {
      expect(
        withoutPlan(LocalDate(2026, 10, 1)).suggestion(householdToday),
        isNull,
      );
    });

    test('sem plano, o mês conta só o que aconteceu', () {
      final month = withoutPlan(LocalDate(2026, 10, 1)).budgetFor(october);

      expect(month.dayToDay, _brl(523.40 + 10 + 30));
      expect(month.cashIncome, Money.zero);
      expect(month.spentPercent, isNull);
    });
  });

  group('RN-1051 · o plano antigo lido como o novo', () {
    test('renda vira o primeiro salário, fixo vira conta fixa, variável vira '
        'dia a dia pelo máximo, e as parcelas soltas continuam contando', () {
      final legacy = MonthSetup(
        cashIncome: _brl(3200),
        debtInstallments: _brl(362),
        fixedExpenses: [
          FixedExpense(
            id: 'aluguel',
            name: 'Aluguel',
            amount: _brl(1100),
            dueDay: 10,
            categoryId: 'rent',
            paymentMethodId: 'bank-slip',
          ),
        ],
        variableBudgets: [
          VariableBudget(
            categoryId: 'groceries',
            range: AmountRange.create(
              min: _brl(500),
              max: _brl(800),
            ).valueOrNull!,
            voucherEligible: true,
          ),
        ],
      );

      final plan = BudgetPlan.fromLegacy(legacy, nameOf: (id) => 'Mercado');

      expect(plan.salaries.single.id, BudgetPlan.firstSalaryId);
      expect(plan.lines.map((line) => line.group), [
        LineGroup.fixedBill,
        LineGroup.dayToDay,
      ]);
      expect(plan.lines.last.amount, _brl(800));
      expect(plan.lines.last.paymentMethodId, 'voucher');
      final month = Finances(
        categories: householdCategories,
        plans: [plan],
      ).budgetFor(october);
      expect(month.debtInstallments, _brl(362));
      expect(month.result, _brl(3200 - 1100 - 800 - 362));
    });
  });
}
