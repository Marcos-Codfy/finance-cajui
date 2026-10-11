import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('os meses por extenso, e com a primeira maiúscula para abrir frase', () {
    expect(CalendarWords.month(const BudgetMonth(2026, 10)), 'outubro');
    expect(CalendarWords.monthCapitalized(const BudgetMonth(2026, 3)), 'Março');
  });

  test('o dia da semana por extenso: 11/10/2026 é domingo', () {
    expect(CalendarWords.weekday(LocalDate(2026, 10, 11)), 'domingo');
    expect(CalendarWords.weekday(LocalDate(2026, 10, 12)), 'segunda');
  });
}
