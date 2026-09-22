import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';

/// Um servidor de mentira que guarda o que recebeu, como o de verdade faria.
///
/// Vive aqui, e não dentro de um teste, porque dois testes da subida o
/// usam: o do livro e o do que entrou.
base class FakeUplink implements LedgerUplink {
  final Map<String, String> entries = {};
  final Set<String> categories = {};
  final List<String> calls = [];

  @override
  bool get isPaired => true;

  /// Nasce sem sessão: a subida silenciosa só age quando há uma aberta, e o
  /// teste que a quer ligada diz isso na cara.
  bool session = false;

  @override
  bool get hasOpenSession => session;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async =>
      (categories, null);

  final Set<String> cards = {};

  @override
  Future<(Set<String>, ErrorCode?)> remoteCards() async => (cards, null);

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async {
    cards.add('${card['id']}');
    return null;
  }

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
  Future<(Map<String, String>, ErrorCode?)> remoteEntries() async =>
      (Map.of(entries), null);

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async {
    categories.add('${category['id']}');
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
    return null;
  }

  @override
  Future<ErrorCode?> cancelEntry(String id) async {
    calls.add('cancelou $id');
    entries.remove(id);
    return null;
  }

  String _signature(CreateEntryRequest entry) => LedgerUplink.signature(
    cents: entry.amountCents,
    occurredOn: entry.occurredOn,
    categoryId: entry.categoryId,
    description: entry.description,
  );
}
