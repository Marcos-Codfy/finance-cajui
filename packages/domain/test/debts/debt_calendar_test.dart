import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';

Money _brl(num reais) => Money.fromCents((reais * 100).round());

Debt _byBalance({int balance = 100000, int payment = 30000}) =>
    Debt.withBalance(
      id: 'atrasada',
      creditor: 'Banco de exemplo',
      kind: DebtKind.overdueBill,
      balance: Money.fromCents(balance),
      monthlyPayment: Money.fromCents(payment),
      dueDay: 5,
      informedOn: LocalDate(2026, 10, 1),
      note: 'negociar à vista',
    ).valueOrNull!;

void main() {
  group('RN-1030 · o saldo da dívida pelo calendário, sem digitar parcela', () {
    test('parcelada: cada vencimento que passa tira uma parcela', () {
      expect(
        DebtCalendar.outstandingOn(carne, LocalDate(2026, 10, 9)),
        _brl(1200),
      );
      expect(
        DebtCalendar.outstandingOn(carne, LocalDate(2026, 10, 10)),
        _brl(1080),
      );
      expect(
        DebtCalendar.outstandingOn(carne, LocalDate(2027, 7, 10)),
        Money.zero,
      );
    });

    test(
      'parcelada: vale o maior entre as pagas no cadastro e as vencidas',
      () {
        final registered = Debt.create(
          id: 'emprestimo',
          creditor: 'Empréstimo',
          kind: DebtKind.loan,
          installmentAmount: _brl(200),
          totalInstallments: 6,
          paidInstallments: 3,
          dueDay: 10,
          firstMonth: october,
        ).valueOrNull!;

        expect(
          DebtCalendar.outstandingOn(registered, LocalDate(2026, 10, 20)),
          _brl(600),
        );
      },
    );

    test('de saldo: cai uma parcela a cada vencimento depois do dia informado, '
        'e nunca fica negativa', () {
      final debt = _byBalance();

      expect(debt.type, DebtType.overdue);
      expect(debt.note, 'negociar à vista');
      expect(
        DebtCalendar.outstandingOn(debt, LocalDate(2026, 10, 4)),
        _brl(1000),
      );
      expect(
        DebtCalendar.outstandingOn(debt, LocalDate(2026, 10, 5)),
        _brl(700),
      );
      expect(
        DebtCalendar.outstandingOn(debt, LocalDate(2027, 2, 5)),
        Money.zero,
      );
      expect(debt.installmentDueIn(const BudgetMonth(2027, 1)), _brl(100));
      expect(debt.installmentDueIn(const BudgetMonth(2027, 2)), Money.zero);
    });

    test('atrasada sem parcela: o saldo fica até ser negociado, e não entra '
        'nas parcelas do mês', () {
      final debt = _byBalance(balance: 380000, payment: 0);

      expect(
        DebtCalendar.outstandingOn(debt, LocalDate(2027, 6, 1)),
        _brl(3800),
      );
      expect(debt.installmentDueIn(october), Money.zero);
      expect(debt.isPaidOff, isFalse);
    });

    test('saldo negativo é recusado', () {
      final result = Debt.withBalance(
        id: 'x',
        creditor: 'x',
        kind: DebtKind.overdueBill,
        balance: _brl(-1),
        monthlyPayment: Money.zero,
        dueDay: 5,
        informedOn: LocalDate(2026, 10, 1),
      );

      expect(result.failureOrNull, isA<NonPositiveAmount>());
    });
  });

  group('RN-1002 · os três tipos da planilha', () {
    test('cada tipo antigo vira parcelado, atrasado ou rotativo', () {
      expect(DebtType.of(DebtKind.loan), DebtType.installments);
      expect(DebtType.of(DebtKind.financing), DebtType.installments);
      expect(DebtType.of(DebtKind.cardInstallment), DebtType.installments);
      expect(DebtType.of(DebtKind.informal), DebtType.installments);
      expect(DebtType.of(DebtKind.cardRevolving), DebtType.revolving);
      expect(DebtType.of(DebtKind.overdueBill), DebtType.overdue);
    });
  });

  group('RN-1031 · a ordem de quitação', () {
    test('primeiro as da lista, depois as outras na ordem em que chegaram', () {
      final atrasada = _byBalance();
      final ordered = DebtOrder.apply(
        [carne, atrasada],
        ['atrasada', 'sumida'],
      );

      expect(ordered.map((debt) => debt.id), ['atrasada', 'carne']);
    });
  });

  group('RN-1032 · quanto ainda devo no fim do mês', () {
    test('dívidas pelo calendário e parcelas de cartão que vencem depois', () {
      expect(
        DebtCalendar.owedAtEndOf(october, debts: [carne, _byBalance()]),
        _brl(1080 + 700),
      );
    });
  });
}
