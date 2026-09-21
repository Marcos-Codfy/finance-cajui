import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/scenario.dart';

Money _cents(int cents) => Money.fromCents(cents);

AmountRange _range(int min, int max) =>
    AmountRange.create(min: _cents(min), max: _cents(max)).valueOrNull!;

void main() {
  group('AmountRange', () {
    test('RN-420 aceita 0 ≤ mínimo ≤ máximo, inclusive iguais', () {
      expect(
        AmountRange.create(min: Money.zero, max: _cents(100)).isOk,
        isTrue,
      );
      expect(AmountRange.create(min: _cents(5), max: _cents(5)).isOk, isTrue);
    });

    test('E-BUDG-01 mínimo acima do máximo, ou negativo, é recusado', () {
      expect(
        AmountRange.create(min: _cents(900), max: _cents(800)).failureOrNull,
        isA<RangeMinAboveMax>(),
      );
      expect(
        AmountRange.create(min: _cents(-1), max: _cents(800)).failureOrNull,
        isA<RangeMinAboveMax>(),
      );
    });
  });

  group('MonthPlan', () {
    test('RN-430 reúne renda, vale, fixos, variáveis e dívidas', () {
      final plan = septemberPlan();

      expect(plan.cashIncome, _cents(320000));
      expect(plan.voucherAvailable, _cents(65000));
      expect(plan.fixedTotal, _cents(130000));
      expect(plan.debtInstallments, _cents(36200));
    });

    test('RN-421 os variáveis entram pelo máximo da faixa', () {
      final transport = septemberPlan().variables[1];

      expect(transport.cashAtMax, _cents(26000));
    });

    test('RN-425 o vale é consumido primeiro na categoria elegível', () {
      final groceries = septemberPlan().variables.first;

      // máx(0, 800 − 650) = 150
      expect(groceries.cashAtMax, _cents(15000));
      expect(groceries.voucherAtMax, _cents(65000));
      expect(septemberPlan().variableCash, _cents(98000));
    });

    test('RN-426 o vale é distribuído na ordem do plano, até acabar', () {
      final planned = PlannedVariable.allocate([
        VariableBudget(
          categoryId: 'groceries',
          range: _range(0, 60000),
          voucherEligible: true,
        ),
        VariableBudget(
          categoryId: 'bakery',
          range: _range(0, 12000),
          voucherEligible: true,
        ),
      ], _cents(65000));

      expect(planned.first.cashAtMax, Money.zero);
      expect(planned.last.voucherAtMax, _cents(5000));
      expect(planned.last.cashAtMax, _cents(7000));
    });

    test('RN-661 a folga em dinheiro do mercado desconta o vale', () {
      final plan = septemberPlan();

      // Gastando o mínimo (500), o vale de 650 cobre tudo: folga de 150.
      expect(plan.variables.first.cashSlack, _cents(15000));
      expect(plan.adjustableSlack, _cents(54000));
    });

    test('RN-411 o fixo pago passa a valer pelo valor pago', () {
      final plan = septemberPlan(paidFixed: {'internet': _cents(10490)});

      expect(plan.fixedTotal, _cents(130490));
      expect(plan.fixed[1].isPaid, isTrue);
    });

    test('RN-415 e RN-427 só entra no plano o que está vigente no mês', () {
      final ended = FixedExpense(
        id: 'gym',
        name: 'Academia',
        amount: _cents(9000),
        dueDay: 5,
        categoryId: 'gym',
        paymentMethodId: 'pix',
        validity: const MonthSpan(until: BudgetMonth(2026, 11)),
      );
      MonthPlan planOf(BudgetMonth month) => MonthPlan.of(
        month: month,
        cashIncome: _cents(320000),
        voucherAvailable: Money.zero,
        fixedExpenses: [ended],
        variableBudgets: const [],
        debtInstallments: Money.zero,
      );

      expect(planOf(const BudgetMonth(2026, 10)).fixedTotal, _cents(9000));
      expect(planOf(const BudgetMonth(2026, 11)).fixedTotal, Money.zero);
    });
  });

  group('FixedOccurrence', () {
    test('RN-414 vencida e sem lançamento fica "em aberto"', () {
      final rent = septemberPlan().fixed.first;

      expect(rent.dueOn, LocalDate(2026, 9, 10));
      expect(rent.isOverdueOn(LocalDate(2026, 9, 10)), isFalse);
      expect(rent.isOverdueOn(LocalDate(2026, 9, 12)), isTrue);
    });

    test('RN-414 paga, deixa de estar em aberto', () {
      final plan = septemberPlan(paidFixed: {'rent': _cents(110000)});

      expect(plan.fixed.first.isOverdueOn(LocalDate(2026, 9, 12)), isFalse);
    });
  });

  group('Reallocation', () {
    Result<Reallocation> move(int cents, {int slack = 8000}) =>
        Reallocation.create(
          id: 'm1',
          month: september,
          fromCategoryId: 'leisure',
          toCategoryId: 'transport',
          amount: _cents(cents),
          originSlack: _cents(slack),
        );

    test('RN-403 mover folga é uma ação explícita, com origem e destino', () {
      final moved = move(8000).valueOrNull!;

      expect(moved.fromCategoryId, 'leisure');
      expect(moved.toCategoryId, 'transport');
      expect(moved.month, september);
    });

    test('E-BUDG-04 não move mais que a folga da origem', () {
      final failure = move(8001).failureOrNull;

      expect(failure, isA<ReallocationExceedsSlack>());
      expect((failure! as ReallocationExceedsSlack).slack, _cents(8000));
    });
  });

  group('MonthClose', () {
    test('RN-442 só fecha depois que o mês termina', () {
      final early = MonthClose.close(
        month: september,
        cashResult: _cents(55800),
        today: LocalDate(2026, 9, 28),
      );

      expect(early.failureOrNull, isA<MonthNotOver>());
      expect(
        (early.failureOrNull! as MonthNotOver).closableFrom,
        LocalDate(2026, 10, 1),
      );
    });

    test(
      'RN-441 lançamento tardio gera revisão, e a anterior é preservada',
      () {
        final first = MonthClose.close(
          month: september,
          cashResult: _cents(55800),
          today: LocalDate(2026, 10, 1),
        ).valueOrNull!;

        final second = first.revisedWith(
          cashResult: _cents(51600),
          on: LocalDate(2026, 10, 3),
        );

        expect(first.revision, 1);
        expect(first.cashResult, _cents(55800));
        expect(second.revision, 2);
        expect(second.differenceFrom(first), _cents(-4200));
      },
    );
  });
}
