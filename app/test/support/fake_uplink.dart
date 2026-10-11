import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';

/// Um servidor de mentira que guarda o que recebeu, como o de verdade faria.
///
/// Vive aqui, e não dentro de um teste, porque dois testes da subida o
/// usam: o do livro e o do que entrou.
base class FakeUplink implements LedgerUplink {
  final Map<String, String> entries = {};

  /// O que o servidor já cancelou por ordem de outro aparelho.
  final Set<String> cancelledOnServer = {};

  /// O carimbo da última correção que o servidor tem, por lançamento.
  final Map<String, DateTime> revisedOnServer = {};
  final Set<String> categories = {};
  final List<String> calls = [];

  @override
  bool get isPaired => true;

  /// Nasce sem envio silencioso: a subida silenciosa só age quando dá, e o
  /// teste que a quer ligada diz isso na cara.
  bool session = false;

  @override
  Future<bool> canSendQuietly() async => session;

  /// O que o servidor tem de cada categoria e de cada cartão, como chegou.
  final Map<String, Map<String, Object?>> catalog = {};

  @override
  Future<(Map<String, CatalogVersion>, ErrorCode?)> remoteCategories() async =>
      (_versions(categories, 'category'), null);

  final Set<String> cards = {};

  @override
  Future<(Map<String, CatalogVersion>, ErrorCode?)> remoteCards() async =>
      (_versions(cards, 'card'), null);

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async {
    cards.add('${card['id']}');
    catalog['card:${card['id']}'] = card;
    return null;
  }

  /// A versão de cada item de [ids]. Item posto pelo teste sem conteúdo é
  /// "o servidor tem, e ninguém tem mais novo": não sobe de novo.
  Map<String, CatalogVersion> _versions(Set<String> ids, String kind) => {
    for (final id in ids)
      id: switch (catalog['$kind:$id']) {
        final payload? => CatalogVersion.of(payload),
        _ => CatalogVersion(signature: '?', definedAt: DateTime.utc(9999)),
      },
  };

  Map<String, Object?>? plan;

  final Set<String> income = {};
  final Set<String> adjustments = {};

  @override
  Future<(RemoteIncome, ErrorCode?)> remoteIncome() async =>
      ((receipts: income, adjustments: adjustments), null);

  @override
  Future<ErrorCode?> sendIncome(Map<String, Object?> receipt) async {
    calls.add('recebeu ${receipt['id']}');
    income.add('${receipt['id']}');
    return null;
  }

  @override
  Future<ErrorCode?> sendVoucherAdjustment(
    Map<String, Object?> adjustment,
  ) async {
    adjustments.add('${adjustment['id']}');
    return null;
  }

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async {
    calls.add('plan');
    this.plan = plan;
    return null;
  }

  @override
  Future<(RemoteEntries, ErrorCode?)> remoteEntries() async => (
    (
      signatures: Map.of(entries),
      revisedAt: Map.of(revisedOnServer),
      cancelled: cancelledOnServer,
    ),
    null,
  );

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async {
    categories.add('${category['id']}');
    catalog['category:${category['id']}'] = category;
    return null;
  }

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    calls.add('criou ${entry.id}');
    entries[entry.id] = _signature(entry);
    return null;
  }

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async {
    calls.add('corrigiu ${entry.id}');
    entries[entry.id] = _signature(entry);
    if (entry.revisedAt case final at?) revisedOnServer[entry.id] = at;
    return null;
  }

  final Set<String> reversals = {};

  @override
  Future<(Set<String>, ErrorCode?)> remoteReversals() async =>
      (reversals, null);

  @override
  Future<ErrorCode?> sendReversal(Map<String, Object?> reversal) async {
    calls.add('estornou ${reversal['id']}');
    reversals.add('${reversal['id']}');
    return null;
  }

  /// Os fatos do aparelho que o servidor já guarda.
  final Set<String> facts = {};

  @override
  Future<(Set<String>, ErrorCode?)> remoteFacts() async => (facts, null);

  @override
  Future<ErrorCode?> sendFact(DeviceFact fact) async {
    calls.add('guardou ${fact.id}');
    facts.add(fact.id);
    return null;
  }

  @override
  Future<ErrorCode?> cancelEntry(String id) async {
    calls.add('cancelou $id');
    entries.remove(id);
    return null;
  }

  String _signature(CreateEntryRequest entry) =>
      LedgerUplink.signatureOf(entry);
}
