import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/statements/application/statement_page.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_page_source.dart';

void main() {
  group('RN-1102 · uma página por vez', () {
    test('a Juju diz em que página está: "Lendo a página 2 de 3"', () async {
      final source = FakePageSource();
      final steps = <(int, int)>[];

      await readStatement(source, [
        statementPage(),
        statementPage(),
        statementPage(),
      ], onPage: (page, of) => steps.add((page, of)));

      expect(steps, [(1, 3), (2, 3), (3, 3)]);
      expect(source.requests.map((r) => r.page), [1, 2, 3]);
      expect(source.requests.map((r) => r.pageCount).toSet(), {3});
    });

    test('a página que falha é tentada mais uma vez', () async {
      final source = FakePageSource({
        2: [
          pageFailed(ErrorCode.net01),
          pageRead(movements: [movementOn(1, 5)]),
        ],
      });

      final reading = await readStatement(source, [
        statementPage(),
        statementPage(),
      ]);

      expect(source.of(2), hasLength(2));
      expect(reading.failedPages, isEmpty);
      expect(reading.lines.single.page, 2);
    });

    test('a página 4 falha duas vezes: as outras seis seguem, e o resultado '
        'diz qual ficou de fora', () async {
      final source = FakePageSource({
        for (var page = 1; page <= 7; page++)
          page: [
            if (page == 4)
              pageFailed(ErrorCode.ai01)
            else
              pageRead(movements: [movementOn(1, 5)]),
          ],
      });

      final reading = await readStatement(
        source,
        List.filled(7, statementPage()),
      );

      expect(reading.failedPages, [4]);
      expect(reading.failure, ErrorCode.ai01);
      expect(reading.lines.map((line) => line.page), [1, 2, 3, 5, 6, 7]);
      expect(source.of(4), hasLength(2));
    });

    test('sem orçamento de IA (E-AI-03), a leitura para sem gastar '
        'pedido', () async {
      final source = FakePageSource({
        1: [pageFailed(ErrorCode.ai03)],
      });

      final reading = await readStatement(
        source,
        List.filled(3, statementPage()),
      );

      expect(source.requests, hasLength(1));
      expect(reading.failedPages, [1, 2, 3]);
      expect(reading.failure, ErrorCode.ai03);
    });
  });

  group('ADR-030 · juntar as páginas', () {
    test('cada linha leva a página e a linha de origem, e o texto original '
        'fica no celular: o servidor só viu [NOME] (RN-1106)', () async {
      final source = FakePageSource({
        1: [
          pageRead(movements: [movementOn(2, 5, cents: 15000)]),
        ],
        2: [
          pageRead(movements: [movementOn(1, 6), movementOn(2, 7)]),
        ],
      });

      final reading = await readStatement(source, [
        statementPage('EXTRATO OUTUBRO\n05/10 PIX ENVIADO JOAO P SILVA 150,00'),
        statementPage('06/10 PADARIA 10,00\n\n07/10 PADARIA 10,00'),
      ]);

      expect(source.requests.first.lines, [
        'EXTRATO OUTUBRO',
        '05/10 PIX ENVIADO [NOME] 150,00',
      ]);
      expect(reading.lines.map((line) => (line.page, line.sourceLine)), [
        (1, 2),
        (2, 1),
        (2, 2),
      ]);
      expect(
        reading.originalOf(reading.lines.first),
        '05/10 PIX ENVIADO JOAO P SILVA 150,00',
      );
      expect(reading.originalOf(reading.lines.last), '07/10 PADARIA 10,00');
    });

    test('o nome da casa também sai mascarado (RN-732)', () async {
      final source = FakePageSource();

      await readStatement(source, [
        statementPage('06/10 DEPOSITO BIANCA SOUZA LIMA 200,00'),
      ], household: const HouseholdNames(names: ['Bianca Souza Lima']));

      expect(source.requests.single.lines, ['06/10 DEPOSITO [NOME] 200,00']);
    });

    test('RN-1107 · resposta lembrada sobre pessoa não vai como '
        'exemplo', () async {
      final source = FakePageSource();

      await readStatement(
        source,
        [statementPage()],
        examples: const {
          'pessoa:joao p silva': 'groceries',
          'padaria boa vista': 'bakery',
        },
      );

      expect(source.requests.single.examples, {'padaria boa vista': 'bakery'});
    });

    test('a imagem só vai quando o OCR da página veio fraco', () async {
      final source = FakePageSource();
      final image = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0]);

      await readStatement(source, [
        StatementPage(
          text: '05/10 PADARIA 10,00\n06/10 MERCADO 20,00',
          image: image,
        ),
        StatementPage(text: 'EXTRAT0 0UT', image: image),
      ]);

      expect(source.requests.first.image, isNull);
      expect(source.requests.last.image, image);
    });
  });
}
