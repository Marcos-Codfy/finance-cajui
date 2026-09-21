import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _september = BudgetMonth(2026, 9);
const _october = BudgetMonth(2026, 10);

void main() {
  group('CreditCard', () {
    test('RN-302 guarda fechamento e vencimento; dia 31 é aceito', () {
      final created = CreditCard.create(
        id: 'c',
        name: 'Cartão',
        closingDay: 31,
        dueDay: 10,
      );

      expect(created.isOk, isTrue);
    });

    test('E-CARD-01 dia fora de 1 a 31 é recusado', () {
      final failure = CreditCard.create(
        id: 'c',
        name: 'Cartão',
        closingDay: 25,
        dueDay: 32,
      ).failureOrNull;

      expect(failure, isA<InvalidCardDay>());
      expect((failure! as InvalidCardDay).day, 32);
    });
  });

  group('StatementCycle', () {
    test('RN-303 o dia do fechamento já é do ciclo seguinte', () {
      final eve = StatementCycle.containing(card, LocalDate(2026, 9, 24));
      final closing = StatementCycle.containing(card, LocalDate(2026, 9, 25));

      expect(eve.dueOn, LocalDate(2026, 10, 5));
      expect(closing.dueOn, LocalDate(2026, 11, 5));
    });

    test('RN-304 vencimento antes do fechamento pertence ao mês seguinte', () {
      final sameMonth = CreditCard.create(
        id: 'c2',
        name: 'Outro',
        closingDay: 5,
        dueDay: 15,
      ).valueOrNull!;

      expect(
        StatementCycle.closingIn(card, _september).dueOn,
        LocalDate(2026, 10, 5),
      );
      expect(
        StatementCycle.closingIn(sameMonth, _september).dueOn,
        LocalDate(2026, 9, 15),
      );
    });

    test('fechamento no dia 31 usa o último dia dos meses curtos', () {
      final endOfMonth = CreditCard.create(
        id: 'c3',
        name: 'Fim do mês',
        closingDay: 31,
        dueDay: 10,
      ).valueOrNull!;

      final cycle = StatementCycle.closingIn(
        endOfMonth,
        const BudgetMonth(2026, 2),
      );

      expect(cycle.closesOn, LocalDate(2026, 2, 28));
      expect(cycle.contains(LocalDate(2026, 2, 27)), isTrue);
      expect(cycle.contains(LocalDate(2026, 2, 28)), isFalse);
    });
  });

  group('compra no cartão', () {
    test('RN-310 à vista conta no mês da compra, não no da fatura', () {
      final purchase = entry(cents: 18640, lines: [credit(18640)]);

      expect(purchase.spentIn(_september).cash, const Money.fromCents(18640));
      expect(purchase.spentIn(_october), TenderAmounts.zero);
    });

    test('RN-311 parcelada conta no mês em que cada fatura vence', () {
      final stove = parceled(
        id: 'stove',
        cents: 96000,
        count: 6,
        on: LocalDate(2026, 9, 19),
      );
      final plan = stove.installmentPlan!;

      expect(plan.installments.first.dueMonth, _october);
      expect(plan.installments.last.dueMonth, const BudgetMonth(2027, 3));
      expect(plan.installments.map((i) => i.amount.cents).toSet(), {16000});
    });

    test('RN-312 o parcelamento não consome o variável do mês da compra', () {
      final stove = parceled(
        id: 'stove',
        cents: 96000,
        count: 6,
        on: LocalDate(2026, 9, 19),
      );

      expect(stove.spentIn(_september), TenderAmounts.zero);
      expect(
        stove.installmentPlan!.installmentDueIn(_october)!.amount,
        const Money.fromCents(16000),
      );
    });

    test('RN-102 o rateio das parcelas não perde centavo', () {
      final plan = parceled(
        id: 'p',
        cents: 10000,
        count: 3,
        on: LocalDate(2026, 9, 1),
      ).installmentPlan!;

      expect(plan.installments.map((i) => i.amount.cents), [3334, 3333, 3333]);
      expect(plan.total, const Money.fromCents(10000));
    });

    test('RN-313 mostra sempre o total ainda comprometido', () {
      final earlyCard = CreditCard.create(
        id: 'early',
        name: 'Fecha dia 5',
        closingDay: 5,
        dueDay: 15,
      ).valueOrNull!;
      final fridge = parceled(
        id: 'fridge',
        cents: 150000,
        count: 10,
        on: LocalDate(2026, 7, 1),
        onCard: earlyCard,
      ).installmentPlan!;

      expect(fridge.installmentDueIn(_september)!.number, 3);
      expect(fridge.committedFrom(_september), const Money.fromCents(120000));
    });

    test('RN-314 com juros, o lançamento vale o preço à vista', () {
      final withInterest = parceled(
        id: 'tv',
        cents: 150000,
        count: 10,
        installmentCents: 16500,
        on: LocalDate(2026, 9, 1),
      );

      expect(withInterest.amount, const Money.fromCents(150000));
      expect(
        withInterest.installmentPlan!.interestTotal,
        const Money.fromCents(15000),
      );
    });
  });

  group('CategoryNamePolicy', () {
    test('RN-207 e RN-301 cartão e fatura não viram categoria', () {
      expect(
        CategoryNamePolicy.check('Cartão Nubank'),
        isA<CategoryRepresentsCard>(),
      );
      expect(CategoryNamePolicy.check('FATURA'), isA<CategoryRepresentsCard>());
    });

    test('nome comum passa, inclusive "crédito de celular"', () {
      expect(CategoryNamePolicy.check('Mercado'), isNull);
      expect(CategoryNamePolicy.check('Crédito de celular'), isNull);
    });
  });
}
