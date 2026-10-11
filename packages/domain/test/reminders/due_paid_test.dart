import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';
import 'reminder_household.dart';

String _brl(int cents) => MoneyFormat.brl(Money.fromCents(cents));

final _fifth = LocalDate(2026, 10, 5);

Entry _paid(int cents, String category, {String id = 'p1', LocalDate? on}) =>
    spend(cents, id: id, category: category, on: on ?? _fifth);

Set<String> _bills(List<Entry> entries) => {
  for (final reminder in remindersOf(reminderFinances(entries: entries)))
    if (reminder.target == ReminderTarget.bills &&
        reminder.dueOn.budgetMonth == october)
      reminder.eventKey.split(':')[1],
};

Settlement _settled(int cents) => Settlement(
  id: 's1',
  cardId: nubank.id,
  dueMonth: const BudgetMonth(2026, 11),
  amount: Money.fromCents(cents),
  paidOn: _fifth,
);

void main() {
  group('RN-1082 · conta já paga não lembra', () {
    test('o aluguel lançado no mês cobre a linha: sem lembrete em outubro, '
        'e o de novembro continua', () {
      final reminders = remindersOf(
        reminderFinances(entries: [_paid(100000, 'rent')]),
      );

      expect(ofEvent(reminders, 'bills:Aluguel:2026-10-10'), isEmpty);
      expect(ofEvent(reminders, 'bills:Aluguel:2026-11-10'), hasLength(2));
    });

    test('Água, Luz e Internet na mesma categoria: o gasto paga na ordem do '
        'vencimento', () {
      expect(_bills([_paid(8000, 'utilities')]), {
        'Aluguel',
        'Nuvem',
        'Luz',
        'Internet',
      });
      expect(
        _bills([_paid(8000, 'utilities'), _paid(18000, 'utilities', id: 'p2')]),
        {'Aluguel', 'Nuvem', 'Internet'},
      );
    });

    test('na dúvida, lembra: a luz paga por 170,00 não cobre os 180,00 '
        'previstos', () {
      expect(
        _bills([_paid(8000, 'utilities'), _paid(17000, 'utilities', id: 'p2')]),
        containsAll(['Luz', 'Internet']),
      );
    });

    test('o gasto paga antes as linhas sem lembrete próprio — Streaming, sem '
        'dia, e Música, no cartão', () {
      expect(_bills([_paid(4000, 'subscriptions')]), contains('Nuvem'));
      expect(_bills([_paid(7000, 'subscriptions')]), isNot(contains('Nuvem')));
    });

    test('o gasto de setembro não paga a conta de outubro', () {
      expect(
        _bills([_paid(100000, 'rent', on: LocalDate(2026, 9, 30))]),
        contains('Aluguel'),
      );
    });
  });

  group('RN-1083 · parcela já paga não lembra', () {
    test('com a primeira parcela paga, só a de novembro, que é a 2 de 10', () {
      final reminders = remindersOf(
        reminderFinances(debts: [carneDebt(paid: 1)]),
      );

      expect(ofEvent(reminders, 'debts:carne:2026-10-10'), isEmpty);
      expect(
        ofEvent(reminders, 'debts:carne:2026-11-10').first.text,
        startsWith('Parcela 2 de 10, ${_brl(12000)}.'),
      );
    });

    test('a dívida de saldo informado lembra o pagamento do mês', () {
      final overdue = Debt.withBalance(
        id: 'luz-atrasada',
        creditor: 'Luz atrasada',
        kind: DebtKind.overdueBill,
        balance: const Money.fromCents(60000),
        monthlyPayment: const Money.fromCents(20000),
        dueDay: 15,
        informedOn: LocalDate(2026, 10, 1),
      ).valueOrNull!;
      final reminders = remindersOf(reminderFinances(debts: [overdue]));

      expect(
        ofEvent(reminders, 'debts:luz-atrasada:2026-10-15').first.text,
        startsWith('${_brl(20000)}. Pelo que está lançado'),
      );
    });

    test('a parcela de compra no cartão antes do app vem na fatura, sem '
        'lembrete próprio (RN-521)', () {
      final tv = Debt.create(
        id: 'tv',
        creditor: 'TV',
        kind: DebtKind.cardInstallment,
        installmentAmount: const Money.fromCents(5000),
        totalInstallments: 10,
        paidInstallments: 0,
        dueDay: 5,
        firstMonth: const BudgetMonth(2026, 11),
        cardId: nubank.id,
      ).valueOrNull!;
      final reminders = remindersOf(
        reminderFinances(
          debts: [carneDebt(), tv],
          entries: [onCard(30000, on: LocalDate(2026, 10, 1))],
        ),
      );

      expect(
        reminders.where((r) => r.eventKey.startsWith('debts:tv')),
        isEmpty,
      );
      expect(
        ofEvent(reminders, 'cards:nubank:2026-11-05').first.text,
        startsWith('${_brl(35000)}.'),
      );
    });
  });

  group('RN-1084 · fatura paga não lembra', () {
    final finances = reminderFinances(
      entries: [onCard(30000, on: LocalDate(2026, 10, 1))],
    );

    test('paga inteira, nada', () {
      final reminders = remindersOf(finances, settlements: [_settled(30000)]);

      expect(ofEvent(reminders, 'cards:nubank:2026-11-05'), isEmpty);
    });

    test('paga em parte, lembra o que falta', () {
      final reminders = remindersOf(finances, settlements: [_settled(10000)]);

      expect(
        ofEvent(reminders, 'cards:nubank:2026-11-05').first.text,
        startsWith('${_brl(20000)}.'),
      );
    });
  });
}
