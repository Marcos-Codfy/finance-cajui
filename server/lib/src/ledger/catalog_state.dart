import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// O cadastro — categorias e cartões —, reconstruído dos eventos com a
/// versão em vigor de cada item (ADR-024).
///
/// Fica separado da projeção dos lançamentos porque tem regra própria: vale
/// a versão **mais nova pelo carimbo**, e não a que chegou por último. Dois
/// celulares sincronizam em horas diferentes, e o que sincroniza tarde não
/// pode desfazer o limite que o outro acabou de trocar. Evento gravado antes
/// do carimbo existir conta como o mais velho.
final class CatalogState {
  final Map<String, Category> _categories = {};
  final Map<String, CreditCard> _cards = {};
  final Map<String, CatalogVersion> _categoryVersions = {};
  final Map<String, CatalogVersion> _cardVersions = {};

  /// As categorias, por identificador.
  Map<String, Category> get categories => Map.unmodifiable(_categories);

  /// Os cartões, por identificador.
  Map<String, CreditCard> get cards => Map.unmodifiable(_cards);

  /// A versão em vigor da categoria [id]; nula se ela não existe.
  CatalogVersion? categoryVersion(String id) => _categoryVersions[id];

  /// A versão em vigor do cartão [id]; nula se ele não existe.
  CatalogVersion? cardVersion(String id) => _cardVersions[id];

  /// A categoria gravada em [payload] entra, se for a versão que vale.
  void applyCategory(Map<String, Object?> payload) {
    final category = CategoryCodec.decode(payload);
    if (_takes(_categoryVersions, category.id, payload)) {
      _categories[category.id] = category;
    }
  }

  /// O cartão gravado em [payload] entra, se for a versão que vale.
  void applyCard(Map<String, Object?> payload) {
    final card = CardCodec.decodeCard(payload);
    if (_takes(_cardVersions, card.id, payload)) _cards[card.id] = card;
  }

  /// A categoria como a listagem a devolve: com o carimbo da versão.
  Map<String, Object?> encodeCategory(Category category) =>
      CatalogVersion.stamped(
        CategoryCodec.encode(category),
        _categoryVersions[category.id]?.definedAt,
      );

  /// O cartão como a listagem o devolve: com o carimbo da versão.
  Map<String, Object?> encodeCard(CreditCard card) => CatalogVersion.stamped(
    CardCodec.encodeCard(card),
    _cardVersions[card.id]?.definedAt,
  );

  static bool _takes(
    Map<String, CatalogVersion> versions,
    String id,
    Map<String, Object?> payload,
  ) {
    final incoming = CatalogVersion.of(payload);
    if (!incoming.replaces(versions[id])) return false;
    versions[id] = incoming;
    return true;
  }
}
