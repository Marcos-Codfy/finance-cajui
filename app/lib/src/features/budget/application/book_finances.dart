import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O livro do aparelho entregue ao domínio, que faz as contas da planilha
/// (ADR-023). Aqui só se escolhe o que entra; nenhuma conta é feita.
abstract final class BookFinances {
  /// Os números da casa a partir de [book].
  ///
  /// O plano no formato antigo entra como um plano a mais, com o carimbo
  /// dele: se a pessoa já salvou um plano da planilha, o mais novo vale;
  /// se não, o antigo continua contando como contava.
  static Finances of(LedgerBook book) => Finances(
    categories: book.categoriesById,
    plans: [
      if (!book.setup.isEmpty)
        BudgetPlan.fromLegacy(book.setup, nameOf: (id) => _nameOf(book, id)),
      ...book.budgetPlans,
    ],
    entries: book.entries,
    reversals: book.reversals,
    receipts: book.receipts,
    debts: book.debts,
    debtVersions: _versions(book),
    debtOrder: book.debtOrder,
    // O pagamento de parcela ligado à dívida já conta pela dívida.
    excluded: book.debtPayments.keys.toSet(),
  );

  /// As versões das dívidas, com a mais nova de cada trocada pela do livro:
  /// é ela que soma as parcelas pagas que o modelo antigo registrava.
  static List<Debt> _versions(LedgerBook book) {
    final versions = book.budget.debtVersions;
    final newest = {
      for (final debt in DebtVersions.of(versions).current) debt.id: debt,
    };
    return [
      for (final version in versions)
        if (identical(version, newest[version.id]))
          book.debtOf(version.id) ?? version
        else
          version,
    ];
  }

  static String _nameOf(LedgerBook book, String categoryId) =>
      book.categories
          .where((category) => category.id == categoryId)
          .firstOrNull
          ?.name ??
      'Conta';
}

/// Os números da casa, a partir do livro em vigor; nulo enquanto ele abre.
final financesProvider = Provider<Finances?>((ref) {
  final book = ref.watch(ledgerProvider).value;
  return book == null ? null : BookFinances.of(book);
});
