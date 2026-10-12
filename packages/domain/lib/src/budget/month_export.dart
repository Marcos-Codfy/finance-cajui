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
  const new _({
    required this.month,
    required this.summary,
    required this.rows,
    this.spentPercent,
  });

  /// O mês [month] de [budget], com os lançamentos de [entries] que caem
  /// nele e os estornos de [reversals] que voltaram nele. [methodName] dá o
  /// nome de cada forma de pagamento pelo identificador. [excluded] são os
  /// pagamentos de parcela ligados a uma dívida: contam pela dívida.
  factory of({
    required BudgetMonth month,
    required MonthBudget budget,
    required Iterable<Entry> entries,
    required Iterable<Reversal> reversals,
    required Map<String, Category> categories,
    required String Function(String methodId) methodName,
    Set<String> excluded = const {},
  }) {
    final rows = _Rows(categories, methodName, budget, excluded);
    final byId = {for (final entry in entries) entry.id: entry};
    return MonthExport._(
      month: month,
      summary: _summary(budget),
      spentPercent: budget.spentPercent,
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

  /// O quanto da renda já está gasto, em percentual (RN-1016); `null` sem
  /// renda em dinheiro (RN-604).
  final int? spentPercent;

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
///
/// O grupo de cada linha é o do Meu mês, e não o bloco cru da categoria: o
/// plano pode pôr a categoria em outro grupo, e a tarifa solta numa
/// categoria de dívida conta no dia a dia (RN-1007). Com o bloco cru, a
/// planilha somava uma anuidade como parcela de dívida, e o Resumo do mesmo
/// arquivo não batia.
final class _Rows {
  new(this._categories, this._methodName, MonthBudget budget, this._excluded)
    : _blockOf = {for (final item in budget.items) item.categoryId: item.block};

  final Map<String, Category> _categories;
  final String Function(String methodId) _methodName;
  final Map<String, Block> _blockOf;
  final Set<String> _excluded;

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
      group: _groupOf(entry.id, entry.categoryId),
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
      group: _groupOf(original.id, original.categoryId),
      method: _methodName(line.paymentMethodId),
      cash: line.tender == Tender.cash ? back : Money.zero,
      voucher: line.tender == Tender.mealVoucher ? back : Money.zero,
      isReversal: true,
    );
  }

  /// O grupo do Meu mês para o lançamento [entryId] da categoria
  /// [categoryId].
  String _groupOf(String entryId, String categoryId) {
    if (_excluded.contains(entryId)) return _groups[Block.debt]!;
    final block = _blockOf[categoryId] ?? _categories[categoryId]?.block;
    if (block == null) return '';
    // Gasto solto em categoria de dívida é dia a dia (RN-1007).
    return _groups[block == Block.debt ? Block.variable : block]!;
  }

  static Money _sum(List<PaymentLine> lines, Tender tender) => lines
      .where((line) => line.tender == tender)
      .fold(Money.zero, (sum, line) => sum + line.amount);
}
