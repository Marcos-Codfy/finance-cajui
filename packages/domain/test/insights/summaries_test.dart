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

/// O cenário de setembro até a segunda semana: R$ 170 na primeira, R$ 260 na
/// segunda — que tinha limite de R$ 236,25.
final List<Entry> _untilWeekTwo = [
  _spend('w1', 17000, 3),
  _spend('w2', 26000, 9, category: 'transport'),
];

WeeklySummary _weekOf(int day, List<Entry> entries) {
  final today = LocalDate(2026, 9, day);
  final spending = MonthSpending.of(
    september,
    entries: entries,
    categories: _categories,
  );
  return WeeklySummary.of(
    today: today,
    plan: septemberPlan(),
    spending: spending,
    week: WeeklyLimit.of(
      week: BudgetWeek.containing(today),
      variableBudget: septemberPlan().variableCash,
      spending: spending,
    ),
  );
}

/// O espaço que o formato da casa põe entre `R$` e o número.
String _brl(String number) => 'R\$${MoneyFormat.nbsp}$number';

void main() {
  group('RN-810 · resumo do dia', () {
    final today = LocalDate(2026, 9, 12);

    test('RN-812 · dia sem lançamento é dito sem cobrança, e mais nada', () {
      final summary = DailySummary.of(today, entries: const []);

      expect(summary.lines, ['Nada lançado hoje.']);
    });

    test('RN-804 · dinheiro e vale lado a lado, nunca somados', () {
      final summary = DailySummary.of(
        today,
        entries: [
          entry(id: 'a', cents: 850, lines: [pix(850)], on: today),
          entry(id: 'b', cents: 3840, lines: [voucher(3840)], on: today),
        ],
      );

      expect(summary.lines.first, contains('${_brl('8,50')} em dinheiro'));
      expect(summary.lines.first, contains('${_brl('38,40')} no vale'));
      expect(summary.lines.first, isNot(contains('46,90')));
      expect(summary.lines.first, endsWith('em 2 lançamentos.'));
    });

    test('RN-811 · traz o que resta na semana e o que espera conferência', () {
      final summary = DailySummary.of(
        LocalDate(2026, 9, 9),
        entries: _untilWeekTwo,
        week: _weekOf(9, _untilWeekTwo).week,
        pendingCaptures: 2,
      );

      expect(summary.lines, [
        'Hoje: ${_brl('260,00')} em 1 lançamento.',
        'A semana passou ${_brl('23,75')} do limite.',
        '2 comprovantes esperando conferência.',
      ]);
    });

    test('RN-644 · em semana partida, "até" é o último dia dela no mês', () {
      final summary = DailySummary.of(
        LocalDate(2026, 9, 29),
        entries: const [],
        week: _weekOf(29, const []).week,
      );

      expect(summary.lines.last, endsWith('até quarta.'));
    });
  });

  group('RN-820 · resumo da semana', () {
    test('RN-805 e RN-822 · semana que passou do limite: o fato, e como o '
        'excesso se diluiu', () {
      final lines = _weekOf(13, _untilWeekTwo).lines;

      expect(
        lines[0],
        'Semana de 7 a 13: ${_brl('260,00')} de ${_brl('236,25')}.',
      );
      expect(lines[1], 'A semana passou ${_brl('23,75')} do limite.');
      expect(
        lines[2],
        'A próxima já considera isso: ${_brl('226,47')}. O limite ficou '
        '${_brl('9,78')} menor do que seria.',
      );
    });

    test('semana dentro do limite mostra a sobra e o limite seguinte', () {
      final lines = _weekOf(6, [_spend('w1', 17000, 3)]).lines;

      expect(lines[1], 'Sobraram ${_brl('26,00')}.');
      expect(lines[2], startsWith('Limite da próxima semana:'));
    });

    test('RN-824 · três dias seguidos sem lançamento são ditos sem acusar', () {
      final lines = _weekOf(13, _untilWeekTwo).lines;

      expect(
        lines,
        contains(
          'Nenhum lançamento de quinta a domingo. Se faltou algum, dá para '
          'lançar agora com a data certa.',
        ),
      );
    });

    test('RN-821 · traz o que vence nos próximos sete dias', () {
      final lines = _weekOf(6, [_spend('w1', 17000, 3)]).lines;

      expect(
        lines,
        contains('Vence quinta, dia 10: Aluguel, ${_brl('1.100,00')}.'),
      );
    });
  });

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

    test('RN-802 e RN-944 · nenhuma frase de nenhum resumo usa termo que o '
        'guia de voz reprova', () {
      final monthly = summary(_untilWeekTwo);
      final all = [
        ..._weekOf(13, _untilWeekTwo).lines,
        ...monthly.howItWent,
        ...monthly.whatComesNext,
        ...DailySummary.of(LocalDate(2026, 9, 9), entries: _untilWeekTwo).lines,
      ].join(' ');

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
