import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/statement_phone.dart';

/// O texto por blocos de uma página em forma de tabela, como o OCR do S22
/// devolveu em 12/10: cada coluna num bloco, e nenhuma linha com a data e
/// o valor juntos.
const _byColumns =
    '01/09\n03/09\n05/09\n08/09\n10/09\n'
    'ASSAI ATACADISTA\nIFD*RESTAURANTE SABOR\nPIX ENVIADO JOAO P SILVA\n'
    'PAGAMENTO DE FATURA\nLOJA ESTRELA\n'
    '412,30\n45,90\n150,00\n1.200,00\n89,90';

void main() {
  test('ADR-030 · o extrato lê a página em linhas, quando o leitor as '
      'remontou; sem elas, o texto de cada página', () {
    const read = ReadText(
      _byColumns,
      pages: [_byColumns],
      rows: [septemberPage],
    );

    expect(read.pageTexts, [septemberPage]);
    expect(read.rowsText, septemberPage);
    expect(const ReadText('só texto').pageTexts, ['só texto']);
    expect(const ReadText('só texto').rowsText, isNull);
    expect(StatementShape.looksLike(_byColumns), isFalse);
  });

  testWidgets('RN-1100 · o extrato cujo texto por blocos separa a data do '
      'valor é reconhecido pelas linhas, e a IA recebe cada linha inteira', (
    tester,
  ) async {
    final pages = septemberSource();
    final phone = await openStatementPhone(
      tester,
      pages: pages,
      read: const ReadText(
        _byColumns,
        pages: [_byColumns],
        rows: [septemberPage],
        pageCount: 1,
      ),
    );

    await phone.share(tester, 'extrato-1');

    expect(
      find.textContaining('Li 5 movimentações de 1 a 10 de setembro.'),
      findsOneWidget,
    );
    final lines = pages.of(1).single.lines;
    expect(
      lines.where((line) => line.contains('01/09') && line.contains('412,30')),
      hasLength(1),
      reason: 'a data, o nome e o valor do Assaí na mesma linha',
    );
  });
}
