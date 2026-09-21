import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/scenario.dart';

Money _cents(int cents) => Money.fromCents(cents);

/// O empréstimo do cenário: R$ 212,00, 12 parcelas, 5 pagas, desde abril.
Result<Debt> _loan({int total = 12, int paid = 5, int cents = 21200}) =>
    Debt.create(
      id: 'loan',
      creditor: 'Empréstimo Banco X',
      kind: DebtKind.loan,
      installmentAmount: _cents(cents),
      totalInstallments: total,
      paidInstallments: paid,
      dueDay: 15,
      firstMonth: const BudgetMonth(2026, 4),
    );

void main() {
  group('Debt', () {
    test('RN-510 o saldo devedor nominal é a soma das parcelas que faltam', () {
      final loan = _loan().valueOrNull!;

      expect(loan.remainingInstallments, 7);
      expect(loan.outstandingBalance, _cents(148400));
    });

    test('RN-541 o já pago aparece ao lado do que falta', () {
      expect(_loan().valueOrNull!.paidSoFar, _cents(106000));
    });

    test('E-DEBT-01 mais parcelas pagas que o total é recusado', () {
      final failure = _loan(paid: 13).failureOrNull;

      expect(failure, isA<PaidInstallmentsExceedTotal>());
      expect((failure! as PaidInstallmentsExceedTotal).paid, 13);
    });

    test('RN-104 parcela de valor zero é recusada', () {
      expect(_loan(cents: 0).failureOrNull, isA<NonPositiveAmount>());
    });

    test('RN-520 e RN-530 pagar a última parcela quita a dívida', () {
      var loan = _loan(paid: 11).valueOrNull!;
      expect(loan.isPaidOff, isFalse);

      loan = loan.withInstallmentPaid();

      expect(loan.paidInstallments, 12);
      expect(loan.isPaidOff, isTrue);
      expect(loan.outstandingBalance, Money.zero);
    });

    test('RN-531 a previsão de quitação é o mês da última parcela', () {
      // 12 parcelas a partir de abril de 2026: a última é em março de 2027.
      expect(_loan().valueOrNull!.payoffForecast, const BudgetMonth(2027, 3));
    });

    test('RN-504 e RN-532 a parcela entra no plano só dentro do calendário', () {
      final loan = _loan().valueOrNull!;

      expect(loan.installmentDueIn(september), _cents(21200));
      expect(loan.installmentDueIn(const BudgetMonth(2027, 3)), _cents(21200));
      expect(loan.installmentDueIn(const BudgetMonth(2027, 4)), Money.zero);
      expect(loan.installmentDueIn(const BudgetMonth(2026, 3)), Money.zero);
    });
  });

  group('PayoffQuote', () {
    test('RN-511 e RN-512 o valor informado envelhece depois de 30 dias', () {
      final quote = PayoffQuote(
        amount: _cents(131000),
        quotedOn: LocalDate(2026, 9, 12),
      );
      final loan = _loan().valueOrNull!.withPayoffQuote(quote);

      expect(loan.payoffQuote!.amount, _cents(131000));
      expect(quote.isStaleOn(LocalDate(2026, 10, 12)), isFalse);
      expect(quote.isStaleOn(LocalDate(2026, 10, 29)), isTrue);
      expect(quote.ageOn(LocalDate(2026, 10, 29)), 47);
    });
  });

  group('DebtSchedule', () {
    test('RN-503 e RN-504 soma dívidas e parcelas de compras no cartão', () {
      // Geladeira em 10× de R$ 150, com a 1ª parcela em julho.
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
      );

      final due = DebtSchedule.dueIn(
        september,
        debts: [_loan().valueOrNull!],
        entries: [fridge],
      );

      // 212 + 150 = 362, o `D` do cenário.
      expect(due, _cents(36200));
    });

    test('RN-330 parcela de compra anterior ao app compõe a fatura do cartão', () {
      final legacy = Debt.create(
        id: 'old',
        creditor: 'Notebook',
        kind: DebtKind.cardInstallment,
        installmentAmount: _cents(30000),
        totalInstallments: 6,
        paidInstallments: 2,
        dueDay: 5,
        firstMonth: const BudgetMonth(2026, 7),
        cardId: 'card',
      ).valueOrNull!;

      Money dueOn(String cardId) => DebtSchedule.legacyCardInstallmentsDueIn(
        september,
        cardId: cardId,
        debts: [legacy, _loan().valueOrNull!],
      );

      expect(dueOn('card'), _cents(30000));
      expect(dueOn('outro'), Money.zero);
    });
  });

  group('PayoffSimulation', () {
    test('RN-533 simula sobre o saldo nominal e diz quantos meses poupa', () {
      final loan = _loan().valueOrNull!;

      // Faltam 1.484,00. Com 212 + 100 por mês: 5 meses, em vez de 7.
      final simulation = PayoffSimulation.withExtra(loan, _cents(10000));

      expect(simulation.monthsToPayoff, 5);
      expect(simulation.monthsSaved, 2);
      expect(PayoffSimulation.basis, 'nominal');
    });
  });
}
