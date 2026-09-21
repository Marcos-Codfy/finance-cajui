import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('LocalDate', () {
    test('é um dia, sem hora: o lançamento das 23h30 não muda de dia', () {
      final lateNight = DateTime(2026, 9, 30, 23, 30);

      expect(LocalDate.fromDateTime(lateNight), LocalDate(2026, 9, 30));
    });

    test('soma dias atravessando mês e ano', () {
      expect(LocalDate(2026, 9, 30).addDays(1), LocalDate(2026, 10, 1));
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
    });

    test('conta os dias entre duas datas, nos dois sentidos', () {
      final start = LocalDate(2026, 9, 28);

      expect(start.daysUntil(LocalDate(2026, 10, 4)), 6);
      expect(LocalDate(2026, 10, 4).daysUntil(start), -6);
    });

    test('a semana vai de segunda (1) a domingo (7)', () {
      expect(LocalDate(2026, 9, 14).weekday, DateTime.monday);
      expect(LocalDate(2026, 9, 20).weekday, DateTime.sunday);
    });

    test('grava e ordena no formato ISO', () {
      final days = [LocalDate(2026, 10, 1), LocalDate(2026, 9, 5)]..sort();

      expect(days.first.toString(), '2026-09-05');
      expect(days.first.isBefore(days.last), isTrue);
    });
  });

  group('BudgetMonth', () {
    test('anda para a frente e para trás atravessando o ano', () {
      expect(const BudgetMonth(2026, 12).next, const BudgetMonth(2027, 1));
      expect(const BudgetMonth(2026, 1).previous, const BudgetMonth(2025, 12));
      expect(
        const BudgetMonth(2026, 9).addMonths(16),
        const BudgetMonth(2028, 1),
      );
    });

    test('conta os meses até outro mês', () {
      const september = BudgetMonth(2026, 9);

      expect(september.monthsUntil(const BudgetMonth(2027, 3)), 6);
      expect(september.monthsUntil(const BudgetMonth(2026, 8)), -1);
    });

    test('sabe o primeiro dia, o último e quantos dias tem', () {
      expect(const BudgetMonth(2026, 9).lastDay, LocalDate(2026, 9, 30));
      expect(const BudgetMonth(2026, 2).length, 28);
      expect(const BudgetMonth(2028, 2).length, 29);
    });

    test('dia 31 num mês curto vira o último dia do mês', () {
      expect(
        const BudgetMonth(2026, 2).dayClamped(31),
        LocalDate(2026, 2, 28),
      );
      expect(
        const BudgetMonth(2026, 9).dayClamped(5),
        LocalDate(2026, 9, 5),
      );
    });

    test('diz se um dia pertence a ele', () {
      const september = BudgetMonth(2026, 9);

      expect(september.contains(LocalDate(2026, 9, 30)), isTrue);
      expect(september.contains(LocalDate(2026, 10, 1)), isFalse);
      expect(LocalDate(2026, 9, 12).budgetMonth, september);
    });
  });
}
