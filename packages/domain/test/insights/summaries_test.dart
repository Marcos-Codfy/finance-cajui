import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../support/scenario.dart';

Category _variable(String id) =>
    Category(id: id, name: id, block: Block.variable, groupId: id);

final Map<String, Category> _categories = {
  for (final id in ['transport', 'leisure', 'pharmacy', 'power'])
    id: _variable(id),
  'groceries': groceries,
};

Entry _spend(String id, int cents, int day, {String category = 'leisure'}) =>
    entry(
      id: id,
      cents: cents,
      lines: [pix(cents)],
      category: _categories[category]!,
      on: LocalDate(2026, 9, day),
    );

/// O cenário de setembro até a segunda semana: R$ 170 na primeira e R$ 260
/// na segunda.
final List<Entry> _untilWeekTwo = [
  _spend('w1', 17000, 3),
  _spend('w2', 26000, 9, category: 'transport'),
];

/// O espaço que o formato da casa põe entre `R$` e o número.
String _brl(String number) => 'R\$${MoneyFormat.nbsp}$number';

void main() {
  group('RN-831 · resumo do mês', () {
    MonthlySummary summary(List<Entry> entries, {MonthPlan? plan}) =>
        MonthlySummary(
          indicators: MonthIndicators(
            plan ?? septemberPlan(),
            MonthSpending.of(
              september,
              entries: entries,
              categories: _categories,
            ),
          ),
          spent: TenderAmounts.zero,
          voucherBalance: const Money.fromCents(41260),
          categoryName: (id) => _categories[id]?.name ?? id,
        );

    test('RN-832 · começa pelo que foi cumprido, e só depois o resultado', () {
      final lines = summary(_untilWeekTwo).howItWent;

      expect(lines[0], '5 de 5 variáveis dentro do previsto.');
      expect(lines[1], startsWith('Pelo que está lançado, setembro fecha com'));
      expect(lines[3], startsWith('Vale: '));
    });

    test('RN-837 · mês com falta tem a mesma estrutura, e a falta é valor a '
        'recompor, com o que dá para fazer', () {
      final short = MonthPlan.of(
        month: september,
        cashIncome: const Money.fromCents(250000),
        voucherAvailable: const Money.fromCents(65000),
        fixedExpenses: fixedExpenses,
        variableBudgets: variableBudgets,
        debtInstallments: const Money.fromCents(36200),
      );
      final monthly = summary(const [], plan: short);

      expect(monthly.howItWent[0], '5 de 5 variáveis dentro do previsto.');
      expect(monthly.howItWent[1], contains('faltam'));
      expect(monthly.whatComesNext, hasLength(lessThanOrEqualTo(4)));
      expect(monthly.whatComesNext.first, startsWith('Ajustar '));
    });

    test('RN-802 e RN-944 · nenhuma frase do resumo do mês usa termo que o '
        'guia de voz reprova', () {
      final monthly = summary(_untilWeekTwo);
      final all = [...monthly.howItWent, ...monthly.whatComesNext].join(' ');

      expect(VoiceGuide.violations(all), isEmpty);
      expect(all, isNot(contains('!')));
    });
  });

  test('MoneyFormat · o formato da casa, com milhar, centavos e sinal', () {
    expect(MoneyFormat.brl(const Money.fromCents(128450)), _brl('1.284,50'));
    expect(MoneyFormat.brl(const Money.fromCents(5)), _brl('0,05'));
    expect(
      MoneyFormat.brl(const Money.fromCents(-1200)),
      '${MoneyFormat.minus}${_brl('12,00')}',
    );
  });
}
