import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'reminder_household.dart';

String _brl(int cents) => MoneyFormat.brl(Money.fromCents(cents));

void main() {
  group('RN-840 RN-1081 · dois dias antes e no dia, às 9h', () {
    test('Aluguel do dia 10, hoje 7: lembretes em 8 e 10 de outubro', () {
      final rent = ofEvent(
        remindersOf(reminderFinances()),
        'bills:Aluguel:2026-10-10',
      );

      expect(
        [for (final r in rent) r.fireOn],
        [LocalDate(2026, 10, 8), LocalDate(2026, 10, 10)],
      );
      expect([for (final r in rent) r.hour], [9, 9]);
      expect(rent.map((r) => r.id).toSet(), hasLength(2));
    });

    test('hoje 9: o de dois dias antes já passou, fica só o do dia', () {
      final rent = ofEvent(
        remindersOf(reminderFinances(), today: LocalDate(2026, 10, 9)),
        'bills:Aluguel:2026-10-10',
      );

      expect([for (final r in rent) r.fireOn], [LocalDate(2026, 10, 10)]);
    });

    test('hoje 11: nada do dia 10, que venceu; os de novembro, em 8 e 10', () {
      final reminders = remindersOf(
        reminderFinances(),
        today: LocalDate(2026, 10, 11),
      );

      expect(ofEvent(reminders, 'bills:Aluguel:2026-10-10'), isEmpty);
      expect(
        [
          for (final r in ofEvent(reminders, 'bills:Aluguel:2026-11-10'))
            r.fireOn,
        ],
        [LocalDate(2026, 11, 8), LocalDate(2026, 11, 10)],
      );
    });

    test('nenhum lembrete chega depois do vencimento, nem antes de hoje', () {
      final reminders = remindersOf(reminderFinances());

      expect(reminders, isNotEmpty);
      for (final reminder in reminders) {
        expect(reminder.fireOn.isAfter(reminder.dueOn), isFalse);
        expect(reminder.fireOn.isBefore(reminderToday), isFalse);
      }
    });

    test('a lista olha 35 dias à frente e vem do mais cedo ao mais tarde', () {
      final reminders = remindersOf(reminderFinances());
      final days = [for (final r in reminders) r.fireOn];

      expect(days, [...days]..sort((a, b) => a.compareTo(b)));
      expect(
        reminders.every((r) => !r.dueOn.isAfter(LocalDate(2026, 11, 11))),
        isTrue,
      );
      expect(ofEvent(reminders, 'bills:Luz:2026-11-15'), isEmpty);
    });
  });

  group('RN-1080 · o que tem lembrete', () {
    test('contas com dia, parcelas e faturas; nunca a conta paga no cartão '
        'nem a sem dia', () {
      final reminders = remindersOf(
        reminderFinances(entries: [onCard(30000, on: LocalDate(2026, 10, 1))]),
      );
      final events = {for (final r in reminders) r.eventKey};

      expect(events, {
        'bills:Aluguel:2026-10-10',
        'bills:Água:2026-10-10',
        'bills:Nuvem:2026-10-12',
        'bills:Luz:2026-10-15',
        'bills:Internet:2026-10-20',
        'bills:Aluguel:2026-11-10',
        'bills:Água:2026-11-10',
        'debts:carne:2026-10-10',
        'debts:carne:2026-11-10',
        'cards:nubank:2026-11-05',
      });
    });

    test('a fatura sem compra nenhuma não tem lembrete', () {
      final reminders = remindersOf(reminderFinances());

      expect(reminders.where((r) => r.target == ReminderTarget.cards), isEmpty);
    });
  });

  group('RN-841 RN-1085 · valor, data e o efeito sobre o mês', () {
    test('conta, dois dias antes, mês com sobra', () {
      final rent = ofEvent(
        remindersOf(reminderFinances()),
        'bills:Aluguel:2026-10-10',
      );

      expect(rent.first.title, 'Aluguel vence sábado, 10');
      expect(
        rent.first.text,
        '${_brl(100000)}. Pelo que está lançado, outubro continua com '
        'sobra de ${_brl(93000)} depois de pagar.',
      );
      expect(rent.last.title, 'Aluguel vence hoje');
      expect(rent.first.oncePerEvent, isFalse);
    });

    test('parcela de dívida diz qual é', () {
      final carne = ofEvent(
        remindersOf(reminderFinances()),
        'debts:carne:2026-10-10',
      );

      expect(carne.first.title, 'Carnê da loja: parcela vence sábado, 10');
      expect(carne.first.text, startsWith('Parcela 1 de 10, ${_brl(12000)}.'));
    });

    test('a fatura lembra que as compras já contaram no mês delas', () {
      final statement = ofEvent(
        remindersOf(
          reminderFinances(
            entries: [onCard(30000, on: LocalDate(2026, 10, 1))],
          ),
        ),
        'cards:nubank:2026-11-05',
      );

      expect(
        [for (final r in statement) r.fireOn],
        [LocalDate(2026, 11, 3), LocalDate(2026, 11, 5)],
      );
      expect(statement.first.title, 'Cartão Nubank: fatura vence quinta, 5');
      expect(
        statement.first.text,
        '${_brl(30000)}. As compras já contam no mês em que foram feitas. '
        'Pelo que está lançado, novembro continua com sobra de '
        '${_brl(93000)} depois de pagar.',
      );
    });
  });

  group('RN-842 RN-846 RN-1086 · pagar deixa o mês com falta', () {
    final reminders = remindersOf(reminderFinances(firstSalary: 50000));

    test('a conta diz quanto falta e aponta para Minhas contas', () {
      final rent = ofEvent(reminders, 'bills:Aluguel:2026-10-10').first;

      expect(
        rent.text,
        '${_brl(100000)}. Pelo que está lançado, depois de pagar faltam '
        '${_brl(24000)} para fechar outubro. Dá para rever em Minhas contas.',
      );
    });

    test('a parcela aponta para as dívidas', () {
      final carne = ofEvent(reminders, 'debts:carne:2026-10-10').first;

      expect(carne.text, endsWith('Dá para rever em Minhas dívidas.'));
    });

    test('com falta, cada vencimento avisa uma vez só', () {
      expect(reminders.every((r) => r.oncePerEvent), isTrue);
    });
  });

  group('RN-843 RN-1085 · na tela bloqueada, nenhum nome e nenhum valor', () {
    test('conta, parcela e fatura', () {
      final reminders = remindersOf(
        reminderFinances(
          firstSalary: 50000,
          entries: [onCard(30000, on: LocalDate(2026, 10, 1))],
        ),
      );
      String publicOf(String key) => ofEvent(reminders, key).first.publicTitle;

      expect(
        publicOf('bills:Aluguel:2026-10-10'),
        'Uma conta vence sábado, 10',
      );
      expect(
        publicOf('debts:carne:2026-10-10'),
        'Uma parcela vence sábado, 10',
      );
      expect(publicOf('cards:nubank:2026-11-05'), 'Uma fatura vence quinta, 5');
      for (final reminder in reminders) {
        expect(reminder.publicText, 'Desbloqueie para ver o valor.');
        expect(
          '${reminder.publicTitle} ${reminder.publicText}',
          isNot(contains(r'R$')),
        );
      }
    });
  });

  group('RN-849 RN-1087 · o toque abre a tela do assunto', () {
    test('conta, parcela e fatura', () {
      final reminders = remindersOf(
        reminderFinances(entries: [onCard(30000, on: LocalDate(2026, 10, 1))]),
      );
      ReminderTarget targetOf(String key) =>
          ofEvent(reminders, key).first.target;

      expect(targetOf('bills:Aluguel:2026-10-10'), ReminderTarget.bills);
      expect(targetOf('debts:carne:2026-10-10'), ReminderTarget.debts);
      expect(targetOf('cards:nubank:2026-11-05'), ReminderTarget.cards);
    });
  });

  test('RN-805 · nenhum lembrete usa termo proibido nem exclamação', () {
    final reminders = [
      ...remindersOf(reminderFinances()),
      ...remindersOf(reminderFinances(firstSalary: 50000)),
    ];

    for (final reminder in reminders) {
      final all = [
        reminder.title,
        reminder.text,
        reminder.publicTitle,
        reminder.publicText,
      ].join(' ');
      expect(VoiceGuide.violations(all), isEmpty);
      expect(all, isNot(contains('!')));
    }
  });
}
