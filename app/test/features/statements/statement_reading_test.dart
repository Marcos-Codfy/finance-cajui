import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_page_source.dart';

void main() {
  group('RN-1105 · o período do extrato', () {
    test('vale o que a primeira página que o escreve disse, e ele vai no '
        'pedido das páginas seguintes', () async {
      final source = FakePageSource({
        1: [
          pageRead(movements: [movementOn(1, 5)]),
        ],
        2: [pageRead(period: const BudgetMonth(2026, 10))],
        3: [pageRead(period: const BudgetMonth(2026, 9))],
      });

      final reading = await readStatement(
        source,
        List.filled(3, statementPage()),
      );

      expect(reading.period, const BudgetMonth(2026, 10));
      expect(source.requests.map((r) => r.period), [
        null,
        null,
        const BudgetMonth(2026, 10),
      ]);
      expect(reading.lines.single.occurredOn, LocalDate(2026, 10, 5));
    });

    test('sem página que o diga, vale o mês da maioria das datas', () async {
      final source = FakePageSource({
        1: [
          pageRead(
            movements: [
              movementOn(1, 28, month: 9),
              movementOn(2, 2),
              movementOn(3, 3),
            ],
          ),
        ],
      });

      final reading = await readStatement(source, [statementPage()]);

      expect(reading.period, const BudgetMonth(2026, 10));
      expect(reading.lines.first.occurredOn, LocalDate(2026, 9, 28));
    });
  });

  group('o que ficou de fora é dito, nunca em silêncio', () {
    test('RN-1101 · "Li as páginas 1 a 20 de 24"', () async {
      final reading = await readStatement(
        FakePageSource(),
        List.filled(20, statementPage()),
        pageCount: 24,
      );

      expect(reading.pagesRead, 20);
      expect(reading.pageCount, 24);
      expect(reading.isComplete, isFalse);
    });

    test('RN-1103 · a página lida em parte aparece no resultado', () async {
      final source = FakePageSource({
        2: [
          pageRead(movements: [movementOn(1, 5)], partial: true),
        ],
      });

      final reading = await readStatement(source, [
        statementPage(),
        statementPage(),
      ]);

      expect(reading.partialPages, [2]);
      expect(reading.lines, hasLength(1));
    });

    test('RN-1104 · até 400 movimentações por extrato; o resto é '
        'dito', () async {
      final page = [for (var line = 1; line <= 60; line++) movementOn(line, 5)];
      final source = FakePageSource({
        for (var number = 1; number <= 7; number++)
          number: [pageRead(movements: page)],
      });

      final reading = await readStatement(
        source,
        List.filled(7, statementPage()),
      );

      expect(reading.lines, hasLength(400));
      expect(reading.beyondLimit, 20);
    });

    test('página sem texto e sem imagem fica de fora sem pedido', () async {
      final source = FakePageSource();

      final reading = await readStatement(source, [
        statementPage(),
        statementPage('   '),
      ]);

      expect(source.requests, hasLength(1));
      expect(reading.failedPages, [2]);
    });
  });
}
