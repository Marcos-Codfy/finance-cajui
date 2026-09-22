import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// A forma que o OCR devolveu de uma **foto** de cupom fiscal: o CNPJ antes
/// do nome, ponto virando vírgula com espaço no meio do documento, "LTDA"
/// virando "LTEA" e "R$" virando "RS".
///
/// É o que a leitura precisa atravessar para o cupom de mercado virar
/// lançamento sem ninguém digitar nada. Os dados são inventados; o ruído é o
/// que apareceu no aparelho.
const _noisy = '''
CNPJ: 11.222, 333/0001-81 MAR DOCE SUPERMERCADOS LTEA
ACSU SO 150 AV JOAQUIM EXEMPLO,5500,PLANO DIRETOR SUL,PALMAS
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Valor total RS 664,41
Desconto total RS 10,83
Valor a Pagar RS 653,58''';

void main() {
  group('ruído do OCR numa foto de cupom', () {
    test('o nome sai junto do CNPJ sujo, sem o documento e sem o endereço', () {
      expect(MerchantReader.nameIn(_noisy), 'MAR DOCE SUPERMERCADOS LTEA');
    });

    test('a forma jurídica torta pelo OCR também sai do nome na tela', () {
      expect(
        MerchantName.pretty(MerchantReader.nameIn(_noisy)),
        'Mar Doce Supermercados',
      );
    });

    test('o ramo e o valor pago sobrevivem ao ruído', () {
      expect(
        MerchantReader.kindIn(MerchantReader.nameIn(_noisy)),
        MerchantKind.supermarket,
      );
      expect(ReceiptFieldReader.amountCandidates(_noisy).single.cents, 65358);
    });
  });
}
