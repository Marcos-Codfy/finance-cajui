import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/export/application/month_exporter.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Levar um mês para planilha (RN-1090): o domínio monta o resumo e as
/// linhas com a mesma conta das telas, e o exportador entrega o arquivo.
class ExportMonth {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, a planilha do mês e o exportador.
  final Ref ref;

  /// Exporta [month].
  Future<void> call(BudgetMonth month) async {
    final book = await ref.read(ledgerProvider.future);
    final finances = ref.read(financesProvider);
    if (finances == null) return;
    final names = {
      for (final method in book.paymentMethods) method.id: method.name,
    };
    final export = MonthExport.of(
      month: month,
      budget: finances.budgetFor(month),
      entries: finances.entries,
      reversals: finances.reversals,
      categories: book.categoriesById,
      methodName: (id) => names[id] ?? id,
    );
    await ref.read(monthExporterProvider).export(export);
  }
}

/// O caso de uso de exportar.
final exportMonthProvider = Provider<ExportMonth>(ExportMonth.new);
