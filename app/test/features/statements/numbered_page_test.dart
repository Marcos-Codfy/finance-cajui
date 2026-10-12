import 'package:cajui/src/features/statements/application/numbered_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uma página fictícia no formato em duas linhas: o banco escreve o Pix numa
/// linha e o nome na de baixo. Nenhum nome, CPF ou valor é de alguém.
const _page =
    'Transferência enviada pelo Pix 150,00\n'
    'FULANO DE TAL - •••.123.456-•• - BANCO EXEMPLO\n'
    '05/10 PADARIA BOA VISTA 12,50\n'
    '05/10 PIX ENVIADO JOAO P SILVA 20,00';

void main() {
  group('RN-1106 · o nome de verdade fica no celular, pelo número da '
      'linha', () {
    final page = NumberedPage.of(_page);

    test('cada nome mascarado está na linha onde foi escrito', () {
      expect(page.people, {2: 'FULANO DE TAL', 4: 'JOAO P SILVA'});
      expect(page.masked[1], '[NOME] - [CPF] - BANCO EXEMPLO');
      expect(page.masked[3], '05/10 PIX ENVIADO [NOME] 20,00');
    });

    test('a movimentação citada na linha do Pix acha o nome na de baixo', () {
      expect(page.personOn(1), 'FULANO DE TAL');
      expect(page.personOn(2), 'FULANO DE TAL');
      expect(page.personOn(4), 'JOAO P SILVA');
    });

    test('linha de compra não pega o nome de ninguém', () {
      expect(page.personOn(3), isNull);
    });
  });

  test('RN-1104 · o valor que o OCR quebrou chega inteiro à IA e fica '
      'inteiro no celular', () {
    final page = NumberedPage.of(
      '01/10 TED RECEBIDA EMPRESA EXEMPLO LTDA  +3.120,,00\n'
      '04/10  COMPRA CARTA0 DROGARIA CENTRAL  -32, 80',
    );

    expect(page.original, [
      '01/10 TED RECEBIDA EMPRESA EXEMPLO LTDA  +3.120,00',
      '04/10  COMPRA CARTA0 DROGARIA CENTRAL  -32,80',
    ]);
    expect(page.masked[1], contains('-32,80'));
  });
}
