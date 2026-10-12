import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_page_source.dart';

/// Uma página FICTÍCIA com três movimentações e o saldo, que não é uma.
const _page =
    '01/10 TED RECEBIDA EMPRESA EXEMPLO LTDA +3.120,00\n'
    '04/10 COMPRA CARTAO DROGARIA CENTRAL -32,80\n'
    '05/10 NETFLIX.COM 39,90\n'
    '05/10 SALDO DO DIA 4.000,00';

void main() {
  group('RN-1104 · linha com data e valor que a IA não trouxe', () {
    test('é pedida de novo, sozinha, e volta para o número dela', () async {
      final source = FakePageSource({
        1: [
          pageRead(movements: [movementOn(3, 5, cents: 3990)]),
          pageRead(
            movements: [
              movementOn(1, 1, cents: 312000),
              movementOn(2, 4, cents: 3280),
            ],
          ),
        ],
      });

      final reading = await readStatement(source, [statementPage(_page)]);

      expect(source.of(1), hasLength(2));
      expect(source.of(1).last.lines, hasLength(2));
      expect(source.of(1).last.lines.first, contains('3.120,00'));
      expect(reading.lines.map((line) => line.sourceLine), [3, 1, 2]);
      expect(reading.unreadLines, 0);
      expect(reading.isComplete, isTrue);
    });

    test('o que nem pedindo de novo veio é contado, e o saldo não', () async {
      final source = FakePageSource({
        1: [
          pageRead(movements: [movementOn(3, 5, cents: 3990)]),
          pageRead(movements: [movementOn(1, 1, cents: 999)]),
        ],
      });

      final reading = await readStatement(source, [statementPage(_page)]);

      expect(reading.lines.map((line) => line.sourceLine), [
        3,
      ], reason: 'valor que a linha não escreve não entra');
      expect(reading.unreadLines, 2);
      expect(reading.isComplete, isFalse);
    });

    test('resposta sem movimentação nenhuma não é repetida: as linhas são '
        'contadas', () async {
      final source = FakePageSource({
        1: [pageRead()],
      });

      final reading = await readStatement(source, [statementPage(_page)]);

      expect(source.of(1), hasLength(1));
      expect(reading.unreadLines, 3);
    });
  });
}
