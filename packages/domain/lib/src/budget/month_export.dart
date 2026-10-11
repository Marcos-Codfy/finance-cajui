import 'package:domain/src/budget/export_row.dart';
import 'package:domain/src/budget/month_budget.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/payment_line.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Um número do resumo do mês exportado, com o nome que a planilha usa.
typedef ExportLine = ({String label, Money amount});

/// O mês pronto para virar planilha (RN-1090): o resumo, com os números e
/// as palavras da planilha do dono (RN-1010 a RN-1017, RN-1060), e os
/// lançamentos e estornos, um por linha.
///
/// O dono veio de uma planilha. Exportar é a garantia de que os dados dele
/// nunca ficam presos no app — e a conta é a mesma das telas, feita aqui,
/// porque quem monta o arquivo não calcula nada.
@immutable
final class MonthExport {
  const new _({required this.month, required this.summary, required this.rows});

  /// O mês [month] de [budget], com os lançamentos de [entries] que caem
  /// nele e os estornos de [reversals] que voltaram nele. [methodName] dá o
  /// nome de cada forma de pagamento pelo identificador.
  factory of({
    required BudgetMonth month,
    required MonthBudget budget,
    required Iterable<Entry> entries,
    required Iterable<Reversal> reversals,
    required Map<String, Category> categories,
    required String Function(String methodId) methodName,
  }) {
    final rows = _Rows(categories, methodName);
    final byId = {for (final entry in entries) entry.id: entry};
    return MonthExport._(
      month: month,
      summary: _summary(budget),
      rows: [
        for (final entry in entries)
          if (entry.occurredOn.budgetMonth == month) rows.entry(entry),
        for (final reversal in reversals)
          if (reversal.occurredOn.budgetMonth == month &&
              byId[reversal.entryId] != null)
            rows.reversal(reversal, byId[reversal.entryId]!),
      ]..sort(_byDay),
    );
  }

  /// O mês.
  final BudgetMonth month;

  /// O resumo, na ordem da planilha: o que entra, o que sai por grupo, o
  /// que o vale paga, o que sai do bolso e a sobra ou a falta.
  final List<ExportLine> summary;

  /// Os lançamentos e estornos do mês, por dia.
  final List<ExportRow> rows;

  /// O total da coluna do dinheiro.
  Money get cashTotal => rows.fold(Money.zero, (sum, row) => sum + row.cash);

  /// O total da coluna do vale — à parte, nunca somado ao dinheiro (RN-111).
  Money get voucherTotal =>
      rows.fold(Money.zero, (sum, row) => sum + row.voucher);

  static int _byDay(ExportRow a, ExportRow b) {
    final day = a.on.compareTo(b.on);
    if (day != 0) return day;
    if (a.isReversal != b.isReversal) return a.isReversal ? 1 : -1;
    return a.description.compareTo(b.description);
  }

  static List<ExportLine> _summary(MonthBudget budget) => [
    (label: 'O que entra, em dinheiro', amount: budget.cashIncome),
    if (budget.voucher.isPositive)
      (label: 'Vale do mês', amount: budget.voucher),
    (label: 'Contas fixas', amount: budget.fixedBills),
    (label: 'Assinaturas', amount: budget.subscriptions),
    (
      label: 'Dia a dia (o maior entre previsto e gasto)',
      amount: budget.dayToDay,
    ),
    (label: 'Parcelas de dívida', amount: budget.debtInstallments),
    if (budget.tithe.isPositive) (label: 'Dízimo', amount: budget.tithe),
    (label: 'Total que sai', amount: budget.totalOut),
    (label: 'O vale paga', amount: budget.voucherCovered),
    (label: 'Sai do bolso', amount: budget.outOfPocket),
    if (budget.closes)
      (label: 'Sobra do mês', amount: budget.result)
    else
      (label: 'Faltam para fechar o mês', amount: budget.shortfall),
  ];
}

/// Monta as linhas, com os nomes que a planilha mostra.
final class _Rows {
  const new(this._categories, this._methodName);

  final Map<String, Category> _categories;
  final String Function(String methodId) _methodName;

  static const Map<Block, String> _groups = {
    Block.fixed: 'Contas fixas',
    Block.subscription: 'Assinaturas',
    Block.variable: 'Dia a dia',
    Block.debt: 'Parcelas de dívida',
  };

  ExportRow entry(Entry entry) {
    final category = _categories[entry.categoryId];
    return ExportRow(
      on: entry.occurredOn,
      description: entry.description,
      category: category?.name ?? entry.categoryId,
      group: category == null ? '' : _groups[category.block]!,
      method: {
        for (final line in entry.paymentLines)
          _methodName(line.paymentMethodId),
      }.join(' + '),
      cash: _sum(entry.paymentLines, Tender.cash),
      voucher: _sum(entry.paymentLines, Tender.mealVoucher),
      installments: entry.installmentPlan?.count,
    );
  }

  /// O estorno vai na forma de pagamento por onde voltou, com o valor
  /// negativo: somar a coluna dá o que de fato saiu no mês.
  ExportRow reversal(Reversal reversal, Entry original) {
    final line = reversal.line;
    final back = -line.amount;
    final category = _categories[original.categoryId];
    return ExportRow(
      on: reversal.occurredOn,
      description: 'Estorno: ${original.description}',
      category: category?.name ?? original.categoryId,
      group: category == null ? '' : _groups[category.block]!,
      method: _methodName(line.paymentMethodId),
      cash: line.tender == Tender.cash ? back : Money.zero,
      voucher: line.tender == Tender.mealVoucher ? back : Money.zero,
      isReversal: true,
    );
  }

  static Money _sum(List<PaymentLine> lines, Tender tender) => lines
      .where((line) => line.tender == tender)
      .fold(Money.zero, (sum, line) => sum + line.amount);
}
