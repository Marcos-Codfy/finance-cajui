import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';

/// A subida do livro pela API do Cajui (RN-781).
///
/// Cada chamada passa por `authenticated`, que põe a chave da casa no
/// cabeçalho (ADR-020): não há sessão a abrir nem digital a pedir.
final class CajuiLedgerApi implements LedgerUplink {
  /// Cria a subida sobre o cliente [_api].
  const new(this._api);

  final CajuiApi _api;

  /// É o celular: há livro para subir.
  @override
  bool get isPaired => true;

  /// Com a chave da casa, sempre: nada a perguntar a ninguém.
  @override
  Future<bool> canSendQuietly() async => _api.hasKey;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/categories', token: token),
    );
    final list = outcome.body?['categories'] as List<Object?>? ?? const [];
    return (
      {for (final item in list) '${(item! as Map<String, Object?>)['id']}'},
      outcome.failure?.code,
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
      outcome.failure?.code,
    );
  }

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/cards', card, token: token),
    );
    return outcome.failure?.code;
  }

  @override
  Future<(RemoteIncome, ErrorCode?)> remoteIncome() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/income', token: token),
    );
    return (
      (
        receipts: _idsOf(outcome.body?['receipts']),
        adjustments: _idsOf(outcome.body?['voucherAdjustments']),
      ),
      outcome.failure?.code,
    );
  }

  /// Os identificadores de uma lista do servidor — de objetos com `id`, ou
  /// de textos soltos, como a lista dos cancelados.
  static Set<String> _idsOf(Object? list) => {
    for (final item in (list as List<Object?>? ?? const []))
      if (item is Map) '${item['id']}' else '$item',
  };

  @override
  Future<ErrorCode?> sendIncome(Map<String, Object?> receipt) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/income', receipt, token: token),
    );
    return outcome.failure?.code;
  }

  @override
  Future<ErrorCode?> sendVoucherAdjustment(
    Map<String, Object?> adjustment,
  ) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/voucher/adjustments', adjustment, token: token),
    );
    return outcome.failure?.code;
  }

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/plan', plan, token: token),
    );
    return outcome.failure?.code;
  }

  @override
  Future<(RemoteEntries, ErrorCode?)> remoteEntries() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/entries', token: token),
    );
    final list = outcome.body?['entries'] as List<Object?>? ?? const [];
    final requests = [for (final item in list) ?_requestOf(item)];
    return (
      (
        signatures: {
          for (final request in requests)
            request.id: LedgerUplink.signatureOf(request),
        },
        revisedAt: {
          for (final request in requests) request.id: ?request.revisedAt,
        },
        cancelled: _idsOf(outcome.body?['cancelledIds']),
      ),
      outcome.failure?.code,
    );
  }

  /// Lançamento que não se lê — formato de um servidor mais novo — fica de
  /// fora da comparação, e não derruba a subida inteira.
  static CreateEntryRequest? _requestOf(Object? item) {
    if (item is! Map) return null;
    try {
      return CreateEntryRequest.fromJson(
        CreateEntryRequest.known(item.cast<String, Object?>()),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/categories', category, token: token),
    );
    return outcome.failure?.code;
  }

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/entries', entry.toJson(), token: token),
    );
    return outcome.failure?.code;
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
    return outcome.failure?.code;
  }

  @override
  Future<(Set<String>, ErrorCode?)> remoteReversals() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/reversals', token: token),
    );
    return (_idsOf(outcome.body?['reversals']), outcome.failure?.code);
  }

  @override
  Future<ErrorCode?> sendReversal(Map<String, Object?> reversal) async {
    final outcome = await _api.authenticated(
      (token) => _api.post(
        '/v1/entries/${reversal['entryId']}/reversals',
        reversal,
        token: token,
      ),
    );
    return outcome.failure?.code;
  }

  @override
  Future<(Set<String>, ErrorCode?)> remoteFacts() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/facts', token: token),
    );
    return (_idsOf(outcome.body?['facts']), outcome.failure?.code);
  }

  @override
  Future<ErrorCode?> sendFact(DeviceFact fact) async {
    final outcome = await _api.authenticated(
      (token) => _api.post('/v1/facts', fact.toJson(), token: token),
    );
    return outcome.failure?.code;
  }

  @override
  Future<ErrorCode?> cancelEntry(String id) async {
    final outcome = await _api.authenticated(
      (token) => _api.send('DELETE', '/v1/entries/$id', token: token),
    );
    return outcome.failure?.code;
  }
}
