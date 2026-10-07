import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// O que o app decide sozinho num lançamento, quando a pessoa não decidiu:
/// categoria, forma de pagamento e descrição.
///
/// Lançar uma despesa precisa de um valor, e de mais nada. A categoria sai
/// do nome do lugar quando ele a entrega — "Padaria Central" é padaria —,
/// e senão fica em Outros, que se corrige depois em um toque; a forma é a
/// última usada, ou Pix; a descrição vazia vira o nome da categoria. O que
/// a pessoa escolheu vale sempre: aqui só se preenche o que ficou vazio.
abstract final class DraftDefaults {
  /// A categoria de quem não escolheu e cujo nome não diz nada.
  static const fallbackCategoryId = 'other';

  /// A forma de quem nunca lançou nada.
  static const fallbackMethodId = 'pix';

  /// [draft] com os vazios preenchidos, pronto para o domínio.
  static EntryDraft complete(EntryDraft draft, LedgerBook book) {
    final category =
        draft.category ??
        _inferred(draft.description, book) ??
        book.categoryOf(fallbackCategoryId);
    final method =
        draft.method ?? lastUsed(book) ?? book.methodOf(fallbackMethodId);
    final description = draft.description.trim();
    return draft.copyWith(
      category: category,
      method: method,
      description: description.isEmpty ? category.name : description,
    );
  }

  /// A forma de pagamento do último lançamento: quem paga tudo no Pix não
  /// escolhe Pix toda vez.
  static PaymentMethod? lastUsed(LedgerBook book) {
    final last = book.entries.lastOrNull;
    if (last == null) return null;
    final id = last.paymentLines.first.paymentMethodId;
    return book.methods.where((method) => method.id == id).firstOrNull;
  }

  /// A categoria que o nome do lugar entrega, pelo ramo (RN-744): o mesmo
  /// leitor que a captura usa, sobre o que a pessoa digitou.
  static Category? _inferred(String description, LedgerBook book) {
    final kind = MerchantReader.kindIn(description);
    final id = DefaultCatalog.categoryByMerchantKind[kind];
    if (id == null) return null;
    return book.categories.where((category) => category.id == id).firstOrNull;
  }
}
