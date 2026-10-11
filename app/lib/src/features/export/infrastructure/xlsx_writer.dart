import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_cell.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_parts.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_sheet.dart';
import 'package:domain/domain.dart';

/// Escreve as abas num arquivo `.xlsx`, que o Excel, o Google Planilhas e o
/// LibreOffice abrem (RN-1090).
abstract final class XlsxWriter {
  /// O tipo do arquivo, para quem o recebe saber com que app abrir.
  static const mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Os bytes do arquivo com as [sheets] abas.
  static Uint8List write(List<XlsxSheet> sheets) {
    final names = [for (final sheet in sheets) sheet.name];
    final archive = Archive()
      ..add(_part('[Content_Types].xml', XlsxParts.contentTypes(names.length)))
      ..add(_part('_rels/.rels', XlsxParts.rootRels))
      ..add(_part('xl/workbook.xml', XlsxParts.workbook(names)))
      ..add(
        _part(
          'xl/_rels/workbook.xml.rels',
          XlsxParts.workbookRels(names.length),
        ),
      )
      ..add(_part('xl/styles.xml', XlsxParts.styles));
    for (final (i, sheet) in sheets.indexed) {
      archive.add(_part('xl/worksheets/sheet${i + 1}.xml', worksheet(sheet)));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  static ArchiveFile _part(String path, String xml) =>
      ArchiveFile.string(path, xml);

  /// O XML da aba [sheet].
  static String worksheet(XlsxSheet sheet) {
    final out = StringBuffer()
      ..writeln(XlsxParts.declaration)
      ..write('<worksheet xmlns="${XlsxParts.mainNs}">')
      ..write(_frozen(sheet.frozenRows))
      ..write('<cols>');
    for (final (i, width) in sheet.widths.indexed) {
      out.write(
        '<col min="${i + 1}" max="${i + 1}" width="$width" customWidth="1"/>',
      );
    }
    out.write('</cols><sheetData>');
    for (final (i, row) in sheet.rows.indexed) {
      out.write('<row r="${i + 1}">');
      for (final (j, cell) in row.indexed) {
        out.write(_cell('${column(j)}${i + 1}', cell));
      }
      out.write('</row>');
    }
    return (out..write('</sheetData></worksheet>')).toString();
  }

  /// As primeiras [rows] linhas paradas ao rolar.
  static String _frozen(int rows) => rows == 0
      ? ''
      : '<sheetViews><sheetView workbookViewId="0"><pane ySplit="$rows" '
            'topLeftCell="A${rows + 1}" activePane="bottomLeft" '
            'state="frozen"/></sheetView></sheetViews>';

  static String _cell(String ref, XlsxCell cell) => switch (cell) {
    XlsxText(:final text, :final bold) => _text(ref, text, bold: bold),
    XlsxMoney(:final amount, :final bold) => _number(
      ref,
      decimal(amount),
      bold ? XlsxParts.boldMoneyStyle : XlsxParts.moneyStyle,
    ),
    XlsxDate(:final date) => _number(
      ref,
      '${serial(date)}',
      XlsxParts.dateStyle,
    ),
    XlsxCount(:final value) => _number(ref, '$value', XlsxParts.countStyle),
    XlsxEmpty() => '',
  };

  static String _text(String ref, String text, {required bool bold}) {
    final style = bold ? ' s="${XlsxParts.boldStyle}"' : '';
    final inline =
        '<is><t xml:space="preserve">${XlsxParts.escape(text)}</t></is>';
    return '<c r="$ref" t="inlineStr"$style>$inline</c>';
  }

  static String _number(String ref, String value, int style) =>
      '<c r="$ref" s="$style"><v>$value</v></c>';

  /// A letra da coluna [index], a partir de zero: 0 → A, 26 → AA.
  static String column(int index) {
    final letter = String.fromCharCode(65 + index % 26);
    return index < 26 ? letter : '${column(index ~/ 26 - 1)}$letter';
  }

  /// [amount] em reais, com ponto decimal e sem arredondar: o valor exato,
  /// que o formato da célula mostra como real.
  static String decimal(Money amount) {
    final cents = amount.cents.abs();
    final sign = amount.isNegative ? '-' : '';
    return '$sign${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
  }

  /// [date] no número de série das planilhas: os dias desde 30/12/1899.
  static int serial(LocalDate date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1899, 12, 30)).inDays;
}
