import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';

/// Onde não há identidade de aparelho: a web, que é modo consulta (ADR-013).
///
/// Lá o livro não sobe — ele **desce**. Quem lança é o celular, e a web só
/// lê o que o servidor já tem.
final class NoLedgerUplink implements LedgerUplink {
  /// Cria a porta vazia.
  const new();

  @override
  bool get isPaired => false;

  @override
  bool get hasOpenSession => false;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async =>
      (const <String>{}, ErrorCode.auth03);

  @override
  Future<(Set<String>, ErrorCode?)> remoteCards() async =>
      (const <String>{}, ErrorCode.auth03);

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async =>
      ErrorCode.auth03;

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async =>
      ErrorCode.auth03;

  @override
  Future<(Map<String, String>, ErrorCode?)> remoteEntries() async =>
      (const <String, String>{}, ErrorCode.auth03);

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async =>
      ErrorCode.auth03;

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async =>
      ErrorCode.auth03;

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async =>
      ErrorCode.auth03;

  @override
  Future<ErrorCode?> cancelEntry(String id) async => ErrorCode.auth03;
}
