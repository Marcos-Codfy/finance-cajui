import 'package:domain/domain.dart';
import 'package:test/test.dart';

final _today = LocalDate(2027, 1, 20);

void main() {
  group('RN-1105 · a data sem ano ganha o ano do extrato', () {
    test('extrato de outubro/2026, "05/10" → 05/10/2026', () {
      expect(
        StatementDates.resolve(
          day: 5,
          month: 10,
          period: const BudgetMonth(2026, 10),
          today: _today,
        ),
        LocalDate(2026, 10, 5),
      );
    });

    test('na virada: extrato de janeiro/2027, "28/12" → 28/12/2026', () {
      expect(
        StatementDates.resolve(
          day: 28,
          month: 12,
          period: const BudgetMonth(2027, 1),
          today: _today,
        ),
        LocalDate(2026, 12, 28),
      );
    });

    test('dia depois de hoje, ou que não existe, faz a linha cair', () {
      expect(
        StatementDates.resolve(
          day: 25,
          month: 1,
          period: const BudgetMonth(2027, 1),
          today: _today,
        ),
        isNull,
      );
      expect(
        StatementDates.resolve(
          day: 30,
          month: 2,
          period: const BudgetMonth(2026, 2),
          today: _today,
        ),
        isNull,
      );
    });

    test('o ano escrito na linha vale', () {
      expect(
        StatementDates.resolve(
          day: 5,
          month: 10,
          year: 2025,
          period: const BudgetMonth(2026, 10),
          today: _today,
        ),
        LocalDate(2025, 10, 5),
      );
    });
  });

  group('RN-1105 · conferir a data da IA contra o texto', () {
    test('as formas que um extrato escreve', () {
      for (final text in [
        '05/10 PADARIA',
        '5/10 PADARIA',
        'PADARIA 05-10',
        '05 OUT PADARIA',
        '05/OUT',
        '05OUT',
        'em 2026-10-05',
      ]) {
        expect(
          StatementDates.writtenIn(text, day: 5, month: 10),
          isTrue,
          reason: text,
        );
      }
    });

    test('"15/10" não é "5/10", e outro mês não serve', () {
      expect(StatementDates.writtenIn('15/10', day: 5, month: 10), isFalse);
      expect(StatementDates.writtenIn('05/11', day: 5, month: 10), isFalse);
      expect(StatementDates.writtenIn('05/100', day: 5, month: 10), isFalse);
    });
  });
}
