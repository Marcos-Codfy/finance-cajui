import 'package:cajui/src/features/export/infrastructure/month_workbook.dart';
import 'package:cajui/src/features/export/infrastructure/xlsx_cell.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

const BudgetMonth _october = BudgetMonth(2026, 10);

PaymentLine _line(String id, PaymentMethodKind kind, int cents) => PaymentLine(
  paymentMethodId: id,
  kind: kind,
  amount: Money.fromCents(cents),
);

Entry _entry(String id, int day, List<PaymentLine> lines) => Entry.create(
  id: id,
  description: 'Compra $id',
  amount: lines.fold(Money.zero, (sum, line) => sum + line.amount),
  occurredOn: LocalDate(2026, 10, day),
  category: DefaultCatalog.emptyBook.categoryOf('groceries'),
  paymentLines: lines,
  today: LocalDate(2026, 12, 31),
).valueOrNull!;

MonthExport _export(List<Entry> entries) {
  final categories = DefaultCatalog.emptyBook.categoriesById;
  return MonthExport.of(
    month: _october,
    budget: Finances(
      categories: categories,
      plans: const [],
      entries: entries,
    ).budgetFor(_october),
    entries: entries,
    reversals: const [],
    categories: categories,
    methodName: (id) => id,
  );
}

void main() {
  test('RN-1090 · o arquivo leva o nome do mês, e as abas são Resumo e '
      'Lançamentos, com os totais no fim', () {
    final sheets = MonthWorkbook.of(
      _export([
        _entry('mercado', 3, [
          _line('vale', PaymentMethodKind.mealVoucher, 3000),
          _line('pix', PaymentMethodKind.pix, 5600),
        ]),
        _entry('padaria', 5, [_line('pix', PaymentMethodKind.pix, 5000)]),
      ]),
    );
    final entries = sheets.last.rows;
    final total = entries.last;

    expect(MonthWorkbook.fileName(_october), 'cajui-outubro-2026.xlsx');
    expect([for (final sheet in sheets) sheet.name], ['Resumo', 'Lançamentos']);
    expect((entries.first.first as XlsxText).text, 'Data');
    expect(entries, hasLength(4), reason: 'título, duas linhas e o total');
    // 56 + 50 em dinheiro; os 30 do vale à parte (RN-111).
    expect((total[5] as XlsxMoney).amount, const Money.fromCents(10600));
    expect((total[6] as XlsxMoney).amount, const Money.fromCents(3000));
  });

  test('o resumo abre com o nome do mês e traz os números do Meu mês', () {
    final summary = MonthWorkbook.of(_export(const [])).first.rows;

    expect((summary.first.single as XlsxText).text, 'Outubro de 2026');
    expect([
      for (final row in summary.skip(2))
        if (row.first case XlsxText(:final text)) text,
    ], contains('Sai do bolso'));
  });
}
