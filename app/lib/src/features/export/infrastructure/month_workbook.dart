import 'package:cajui/src/features/export/infrastructure/xlsx_cell.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_sheet.dart';
import 'package:domain/domain.dart';

/// O desenho da planilha do mês (RN-1090): a aba "Resumo", com os números
/// do Meu mês, e a aba "Lançamentos", uma linha por lançamento, com o
/// título parado no alto e os totais no fim.
///
/// Só arruma o que o domínio já contou: nenhum número nasce aqui.
abstract final class MonthWorkbook {
  /// O nome do arquivo de [month]: "cajui-outubro-2026.xlsx".
  static String fileName(BudgetMonth month) =>
      'cajui-${CalendarWords.month(month)}-${month.year}.xlsx';

  /// As duas abas de [month].
  static List<XlsxSheet> of(MonthExport month) => [
    _summary(month),
    _entries(month),
  ];

  static XlsxSheet _summary(MonthExport month) => XlsxSheet(
    name: 'Resumo',
    widths: const [44, 18],
    rows: [
      [
        XlsxText(
          '${CalendarWords.monthCapitalized(month.month)} de '
          '${month.month.year}',
          bold: true,
        ),
      ],
      const [XlsxEmpty()],
      for (final line in month.summary)
        [XlsxText(line.label), XlsxMoney(line.amount)],
      // O "já está gasto" do Meu mês (RN-1016), em percentual; sem renda
      // em dinheiro não há como dizer (RN-604).
      if (month.spentPercent case final percent?)
        [
          const XlsxText('Já está gasto, da renda em dinheiro'),
          XlsxPercent(percent),
        ],
    ],
  );

  static const List<String> _titles = [
    'Data',
    'Descrição',
    'Categoria',
    'Grupo',
    'Forma de pagamento',
    'Dinheiro',
    'Vale',
    'Parcelas',
  ];

  static XlsxSheet _entries(MonthExport month) => XlsxSheet(
    name: 'Lançamentos',
    widths: const [12, 34, 22, 20, 26, 16, 14, 10],
    frozenRows: 1,
    rows: [
      [for (final title in _titles) XlsxText(title, bold: true)],
      for (final row in month.rows) _row(row),
      [
        const XlsxText('Total', bold: true),
        for (var i = 0; i < 4; i++) const XlsxEmpty(),
        XlsxMoney(month.cashTotal, bold: true),
        XlsxMoney(month.voucherTotal, bold: true),
      ],
    ],
  );

  static List<XlsxCell> _row(ExportRow row) => [
    XlsxDate(row.on),
    XlsxText(row.description),
    XlsxText(row.category),
    XlsxText(row.group),
    XlsxText(row.method),
    XlsxMoney(row.cash),
    XlsxMoney(row.voucher),
    if (row.installments case final count?) XlsxCount(count),
  ];
}
