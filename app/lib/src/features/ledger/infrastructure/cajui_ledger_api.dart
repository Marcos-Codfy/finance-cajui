import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';

/// A subida do livro pela API do Cajui (RN-781).
///
/// Cada chamada passa por `authenticated`, então a sessão se abre e se renova
/// sozinha — e a digital é pedida uma vez só por sessão, não uma vez por
/// lançamento.
final class CajuiLedgerApi implements LedgerUplink {
  /// Cria a subida sobre o cliente [_api].
  const new(this._api);

  final CajuiApi _api;

  /// Há Keystore neste aparelho, então há identidade para provar. Se o
  /// servidor ainda não o conhece, ele mesmo recusa — e a recusa vem com o
  /// código do catálogo.
  @override
  bool get isPaired => true;

  @override
  bool get hasOpenSession => _api.isOpen;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/categories', token: token),
    );
    final list = outcome.body?['categories'] as List<Object?>? ?? const [];
    return (
      {for (final item in list) '${(item! as Map<String, Object?>)['id']}'},
      outcome.error,
    );
  }

  @override
  Future<(Set<String>, ErrorCode?)> remoteCards() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/cards', token: token),
    );
    final list = outcome.body?['cards'] as List<Object?>? ?? const [];
    return (
      {for (final item in list) '${(item! as Map<String, Object?>)['id']}'},
      outcome.error,
    );
  }

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/cards', card, token: token),
    );
    return outcome.error;
  }

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/plan', plan, token: token),
    );
    return outcome.error;
  }

  @override
  Future<(Map<String, String>, ErrorCode?)> remoteEntries() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/entries', token: token),
    );
    final list = outcome.body?['entries'] as List<Object?>? ?? const [];
    return ({for (final item in list) ..._signed(item)}, outcome.error);
  }

  Map<String, String> _signed(Object? item) {
    final entry = item! as Map<String, Object?>;
    return {
      '${entry['id']}': LedgerUplink.signature(
        cents: entry['amountCents']! as int,
        occurredOn: '${entry['occurredOn']}',
        categoryId: '${entry['categoryId']}',
        description: '${entry['description']}',
      ),
    };
  }

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/categories', category, token: token),
    );
    return outcome.error;
  }

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/entries', entry.toJson(), token: token),
    );
    return outcome.error;
  }

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async {
    final outcome = await _api.authenticated(
      (token) => _api.send(
        'PUT',
        '/v1/entries/${entry.id}',
        token: token,
        body: entry.toJson(),
      ),
    );
    return outcome.error;
  }

  @override
  Future<ErrorCode?> cancelEntry(String id) async {
    final outcome = await _api.authenticated(
      (token) => _api.send('DELETE', '/v1/entries/$id', token: token),
    );
    return outcome.error;
  }
}
