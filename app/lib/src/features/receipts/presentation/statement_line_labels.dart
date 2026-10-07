import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/receipts/application/statement_import.dart';
import 'package:domain/domain.dart';

/// Os textos de uma linha de extrato: o que ela é, por onde saiu e o rótulo
/// do botão de lançar.
///
/// A forma de pagamento aparece em cada despesa porque é ela que decide em
/// que moeda o gasto conta: ver "Débito" ou "Vale" na linha é o que deixa a
/// pessoa notar uma leitura errada antes de lançar (RN-111).
abstract final class StatementLineLabels {
  /// O que a linha é, em palavras.
  static String what(StatementLine line, LedgerBook book) =>
      switch (line.kind) {
        StatementLineKind.expense => _expense(line, book),
        StatementLineKind.income =>
          StatementImport.isPlanIncome(line, book)
              ? 'Entrada · renda do mês'
              : 'Entrada',
        StatementLineKind.cardPayment =>
          line.doubtful
              ? 'Parece pagamento de fatura'
              : 'Pagamento de fatura, não é despesa',
        StatementLineKind.ownTransfer =>
          line.doubtful
              ? 'Parece transferência entre contas suas'
              : 'Entre contas suas, não é despesa',
      };

  static String _expense(StatementLine line, LedgerBook book) {
    final category = book.categories
        .where((category) => category.id == line.categoryId)
        .firstOrNull
        ?.name;
    final kind = line.doubtful ? 'Tipo incerto' : (category ?? 'Despesa');
    final method = StatementImport.methodFor(line, book)?.name;
    return method == null ? kind : '$kind · $method';
  }

  /// O rótulo do botão de lançar, pela quantidade marcada.
  static String recordLabel(int count) => switch (count) {
    0 => 'Marque o que lançar',
    1 => 'Lançar 1 movimentação',
    _ => 'Lançar $count movimentações',
  };
}
