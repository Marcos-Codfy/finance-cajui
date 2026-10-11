import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_cell.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_sheet.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_writer.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// O arquivo aberto de volta: cada parte do zip, em texto.
Map<String, String> _unzip(List<int> bytes) => {
  for (final file in ZipDecoder().decodeBytes(bytes))
    file.name: utf8.decode(file.content),
};

void main() {
  group('RN-1090 · o .xlsx que o Excel abre', () {
    final bytes = XlsxWriter.write([
      XlsxSheet(
        name: 'Lançamentos',
        widths: const [12, 30],
        frozenRows: 1,
        rows: [
          const [XlsxText('Data', bold: true), XlsxText('Valor')],
          [
            XlsxDate(LocalDate(2026, 10, 3)),
            const XlsxMoney(Money.fromCents(123456)),
          ],
          const [
            XlsxText('Pão & café <manhã>'),
            XlsxMoney(Money.fromCents(-1050), bold: true),
          ],
        ],
      ),
      const XlsxSheet(name: 'Resumo', widths: [40], rows: []),
    ]);
    final parts = _unzip(bytes);

    test('traz as partes que todo .xlsx precisa, uma aba por planilha', () {
      expect(
        parts.keys,
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'xl/workbook.xml',
          'xl/_rels/workbook.xml.rels',
          'xl/styles.xml',
          'xl/worksheets/sheet1.xml',
          'xl/worksheets/sheet2.xml',
        ]),
      );
      expect(parts['xl/workbook.xml'], contains('name="Lançamentos"'));
      expect(parts['xl/workbook.xml'], contains('name="Resumo"'));
    });

    test('dinheiro é número exato com o formato de real; data é número de '
        'série com o formato brasileiro', () {
      final sheet = parts['xl/worksheets/sheet1.xml']!;

      // 03/10/2026 = 46.298 dias desde 30/12/1899.
      expect(sheet, contains('<c r="A2" s="4"><v>46298</v></c>'));
      expect(sheet, contains('<c r="B2" s="2"><v>1234.56</v></c>'));
      expect(sheet, contains('<c r="B3" s="3"><v>-10.50</v></c>'));
      expect(parts['xl/styles.xml'], contains('formatCode="dd/mm/yyyy"'));
    });

    test('texto vai escapado, e o título fica parado ao rolar', () {
      final sheet = parts['xl/worksheets/sheet1.xml']!;

      expect(sheet, contains('Pão &amp; café &lt;manhã&gt;'));
      expect(sheet, contains('state="frozen"'));
      expect(sheet, contains('<c r="A1" t="inlineStr" s="1">'));
    });

    test('as colunas passam do Z como no Excel', () {
      expect(
        [
          for (final i in [0, 25, 26, 27, 51, 52]) XlsxWriter.column(i),
        ],
        ['A', 'Z', 'AA', 'AB', 'AZ', 'BA'],
      );
    });
  });
}
