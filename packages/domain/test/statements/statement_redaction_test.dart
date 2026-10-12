import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Uma página de extrato como o OCR a devolve: o nome de quem recebeu ou
/// mandou o Pix vem solto na linha, sem rótulo e sem CPF por perto.
const _page = '''
EXTRATO CONTA CORRENTE
05/10 PIX ENVIADO JOAO P SILVA 150,00
06/10 PIX RECEBIDO MARIA DE SOUZA LIMA 320,00
07/10 PIX ENVIADO MERCADO BOA VISTA LTDA 89,90
08/10 TED JOSE CARLOS PEREIRA 1.200,00
09/10 IFD*RESTAURANTE SABOR 45,90''';

void main() {
  group('RN-1106 · o nome de pessoa num Pix vira [NOME] antes da IA', () {
    final redacted = PiiRedactor.redact(_page).split('\n');

    test('"PIX ENVIADO JOAO P SILVA 150,00" vai como "PIX ENVIADO [NOME] '
        '150,00"', () {
      expect(redacted[1], '05/10 PIX ENVIADO [NOME] 150,00');
      expect(redacted[2], '06/10 PIX RECEBIDO [NOME] 320,00');
      expect(redacted[4], '08/10 TED [NOME] 1.200,00');
    });

    test('empresa e compra continuam legíveis', () {
      expect(redacted[3], contains('MERCADO BOA VISTA LTDA'));
      expect(redacted[5], contains('IFD*RESTAURANTE SABOR'));
    });

    test('uma linha de cada vez: o número de linhas não muda', () {
      expect(redacted, hasLength(_page.split('\n').length));
      expect(redacted.join('\n'), isNot(contains('SILVA')));
      expect(redacted.join('\n'), isNot(contains('SOUZA')));
    });
  });

  group('RN-1106 · nenhuma máscara junta duas linhas', () {
    test('telefone partido pelo OCR vira o marcador e uma linha vazia', () {
      final redacted = PiiRedactor.redact('Fone (11)\n91234-5678\nTOTAL');

      expect(redacted, 'Fone [TELEFONE]\n\nTOTAL');
    });

    test('saldo com o valor na linha de baixo não junta as linhas', () {
      final redacted = PiiRedactor.redact('SALDO DO DIA\n1.234,56\nPADARIA');

      expect(redacted.split('\n'), hasLength(3));
      expect(redacted, isNot(contains('1.234,56')));
    });

    test('as linhas de uma página voltam cada uma na sua posição', () {
      final lines = PiiRedactor.redactLines(const [
        'De',
        'FULANO DE TAL',
        'DA SILVA',
        'CPF ***.123.456-**',
        '05/10 PIX ENVIADO JOAO P SILVA 150,00',
      ]);

      expect(lines, [
        'De',
        '[NOME]',
        '[NOME]',
        'CPF [CPF]',
        '05/10 PIX ENVIADO [NOME] 150,00',
      ]);
    });

    test('nome da casa com quebra de linha não é trocado', () {
      final redacted = PiiRedactor.redact(
        'BIANCA\nSOUZA\nPADARIA',
        householdNames: ['Bianca\nSouza'],
      );

      expect(redacted.split('\n'), hasLength(3));
    });
  });
}
