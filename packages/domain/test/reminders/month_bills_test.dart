import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';
import 'reminder_household.dart';

List<String> _names(List<MonthBill> bills) => [
  for (final bill in bills) bill.line.name,
];

void main() {
  group('a linha do tempo das contas do mês', () {
    test(
      'só as contas com dia, por data; sem dia e no cartão ficam de fora',
      () {
        final bills = MonthBills.of(
          reminderFinances(),
          october,
          cardIds: {nubank.id},
        );

        expect(_names(bills), ['Aluguel', 'Água', 'Nuvem', 'Luz', 'Internet']);
        expect(bills.first.dueOn, LocalDate(2026, 10, 10));
        expect(bills.every((bill) => !bill.paid), isTrue);
      },
    );

    test('o gasto da categoria paga a conta, na ordem do vencimento', () {
      final bills = MonthBills.of(
        reminderFinances(
          entries: [
            spend(100000, id: 'aluguel', category: 'rent', on: reminderToday),
            spend(8000, id: 'agua', category: 'utilities', on: reminderToday),
          ],
        ),
        october,
        cardIds: {nubank.id},
      );
      final paid = {for (final bill in bills) bill.line.name: bill.paid};

      expect(paid['Aluguel'], isTrue);
      expect(paid['Água'], isTrue);
      expect(paid['Luz'], isFalse);
      expect(paid['Internet'], isFalse);
    });
  });

  group('as contas pagas no cartão vão para a aba de cartões', () {
    test('o que "Minhas contas" cobra no cartão aparece nele, e só nele', () {
      final finances = reminderFinances();

      expect(
        finances.plannedOnCard(nubank, october),
        const Money.fromCents(2000),
        reason: 'a Música é a única conta paga no Nubank',
      );
    });

    test('cartão sem conta do plano não ganha previsto', () {
      final other = CreditCard.create(
        id: 'outro',
        name: 'Outro',
        closingDay: 1,
        dueDay: 8,
      ).valueOrNull!;

      expect(reminderFinances().plannedOnCard(other, october), Money.zero);
    });
  });
}
