import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-1100 · o extrato se reconhece no celular, antes da IA', () {
    test('linhas com data no começo e valor: extrato', () {
      const statement =
          '01/10 TED RECEBIDA EMPRESA EXEMPLO 3.120,00\n'
          '01/10 COMPRA CARTAO ASSAI ATACADISTA -412,30\n'
          '02/10 COMPRA CARTAO MP*PADARIA BOA VISTA -18,50\n'
          '03/10 COMPRA CARTAO IFD*RESTAURANTE SABOR -45,90\n'
          '04/10 PAGAMENTO DE FATURA CARTAO -1.200,00';

      expect(StatementShape.looksLike(statement), isTrue);
    });

    test('com "extrato" no texto, três linhas bastam; e "05 OUT" é data', () {
      const statement =
          'EXTRATO DA CONTA\n'
          '05 OUT PADARIA 8,50\n'
          '06 OUT MERCADO 40,00\n'
          '07 OUT FARMACIA 22,10';

      expect(StatementShape.looksLike(statement), isTrue);
    });

    test('um cupom de mercado não é extrato, por mais valores que tenha', () {
      const receipt =
          'SUPERMERCADO BOA COMPRA LTDA\n'
          'CNPJ 12.345.678/0001-90\n'
          '001 ARROZ 5KG 1 UN 25,90\n'
          '002 FEIJAO 1KG 1 UN 8,49\n'
          '003 OLEO 900ML 2 UN 13,98\n'
          '004 CAFE 500G 1 UN 18,90\n'
          '005 ACUCAR 1KG 1 UN 4,99\n'
          'TOTAL R\$ 72,26\n'
          '12/10/2026 18:42';

      expect(StatementShape.looksLike(receipt), isFalse);
    });

    test('RN-1104 · movimentação é linha com data e valor que não é saldo '
        'nem total', () {
      expect(
        StatementShape.isMovement('01/10  TED RECEBIDA EMPRESA  +3.120,00'),
        isTrue,
      );
      expect(
        StatementShape.isMovement('04/10  COMPRA CARTAO DROGARIA  -32,80'),
        isTrue,
      );
      expect(
        StatementShape.isMovement('01/10  SALDO ANTERIOR  1.000,00'),
        isFalse,
      );
      expect(StatementShape.isMovement('BANCO FICTICIO S.A.'), isFalse);
      expect(StatementShape.isMovement('01/10  TARIFA'), isFalse);
    });

    test('um comprovante de Pix não é extrato', () {
      const pix =
          'Comprovante de Pix\n'
          'Valor R\$ 150,00\n'
          '12/10/2026 10:22\n'
          'Para Fulano de Tal';

      expect(StatementShape.looksLike(pix), isFalse);
    });
  });
}
