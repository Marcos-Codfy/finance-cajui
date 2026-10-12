import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-1104 · o número que o OCR quebrou volta inteiro', () {
    test('as linhas do extrato FICTÍCIO lidas no S22 em 12/10', () {
      expect(
        OcrLine.tidy('01/10 TED RECEBIDA EMPRESA EXEMPLO LTDA  +3.120,,00'),
        '01/10 TED RECEBIDA EMPRESA EXEMPLO LTDA  +3.120,00',
      );
      expect(
        OcrLine.tidy('04/10  COMPRA CARTA0 DROGARIA CENTRAL  -32, 80'),
        '04/10  COMPRA CARTA0 DROGARIA CENTRAL  -32,80',
      );
      expect(
        OcrLine.tidy('SALDO EM 11/ 10/2026  2.418, 33'),
        'SALDO EM 11/10/2026  2.418,33',
      );
    });

    test('o que já está certo não muda, e valores vizinhos não se juntam', () {
      for (final line in [
        '01/10  COMPRA CARTAO ASSAI ATACADISTA  -412,30',
        '04/10 PAGAMENTO DE FATURA CARTAO  -1.200,00',
        'VALORES 12,00, 13,00',
        'CLIENTE: TESTE AG 0000 CC 00000-0',
      ]) {
        expect(OcrLine.tidy(line), line);
      }
    });

    test('consertada, a linha volta a ser movimentação', () {
      const broken = '04/10  COMPRA CARTA0 DROGARIA CENTRAL  -32, 80';

      expect(StatementShape.isMovement(broken), isFalse);
      expect(StatementShape.isMovement(OcrLine.tidy(broken)), isTrue);
      expect(
        ReceiptFieldReader.amountsIn(OcrLine.tidy(broken)),
        contains(const Money.fromCents(3280)),
      );
    });
  });
}
