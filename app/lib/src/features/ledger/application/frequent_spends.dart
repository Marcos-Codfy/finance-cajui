import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os gastos que se repetem, para o "Novo gasto" oferecer de um toque. Quem
/// escolhe e ordena é o domínio (`FrequentSpend.rank`); aqui só se lê o
/// livro e se monta o rascunho.
abstract final class FrequentSpends {
  /// [draft] com o que [spend] traz: descrição, valor, categoria e forma de
  /// pagamento da última vez. A data fica — é a do gasto de agora.
  ///
  /// Categoria ou forma apagada desde então não volta: o campo fica como
  /// estava, e a pessoa escolhe.
  static EntryDraft repeat(
    EntryDraft draft,
    FrequentSpend spend,
    LedgerBook book,
  ) => draft.copyWith(
    description: spend.description,
    amountCents: spend.amount.cents,
    category: book.categories
        .where((category) => category.id == spend.categoryId)
        .firstOrNull,
    method: book.methods
        .where((method) => method.id == spend.paymentMethodId)
        .firstOrNull,
  );
}

/// As sugestões do livro aberto; vazia enquanto ele não abre.
final Provider<List<FrequentSpend>> frequentSpendsProvider =
    Provider.autoDispose((ref) {
      final book = ref.watch(ledgerProvider).value;
      if (book == null) return const [];
      return FrequentSpend.rank(book.entries, today: ref.watch(todayProvider));
    });
