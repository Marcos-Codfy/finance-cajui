import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/device_facts.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';

/// Um servidor de mentira que **guarda e devolve**: o que um aparelho sobe,
/// o outro desce. É o que permite testar dois celulares conversando sem
/// rede nenhuma (BL-062).
///
/// Guarda o que o servidor de verdade guarda — os pedidos, e não os
/// lançamentos prontos — e reconstrói na descida com os mesmos codecs, para
/// o teste passar pelo mesmo caminho que o app passa.
final class FakeExchange implements LedgerUplink, LedgerDownlink {
  final Map<String, CreateEntryRequest> _entries = {};
  final Set<String> _cancelled = {};
  final Map<String, Map<String, Object?>> _cards = {};
  final Map<String, IncomeReceipt> _receipts = {};
  final Map<String, VoucherAdjustment> _adjustments = {};
  final Map<String, Map<String, Object?>> _reversals = {};
  MonthSetup _plan = MonthSetup.empty;

  /// Quantas descidas já foram pedidas.
  int snapshots = 0;

  /// Os lançamentos vivos no servidor, por identificador.
  Map<String, CreateEntryRequest> get entries => Map.unmodifiable(_entries);

  /// O plano que o servidor tem.
  MonthSetup get plan => _plan;

  @override
  bool get isPaired => true;

  /// Sem envio silencioso, de propósito: o teste sincroniza só quando
  /// manda, para saber o que aconteceu quando.
  @override
  Future<bool> canSendQuietly() async => false;

  /// As categorias que o servidor tem, como chegaram. Nasce com o cadastro
  /// de fábrica, sem carimbo — como o servidor de antes da ADR-024.
  final Map<String, Map<String, Object?>> categories = {
    for (final c in DefaultCatalog.emptyBook.categories)
      c.id: CategoryCodec.encode(c),
  };

  @override
  Future<(Map<String, CatalogVersion>, ErrorCode?)> remoteCategories() async =>
      (
        {for (final e in categories.entries) e.key: CatalogVersion.of(e.value)},
        null,
      );

  @override
  Future<(Map<String, CatalogVersion>, ErrorCode?)> remoteCards() async => (
    {for (final e in _cards.entries) e.key: CatalogVersion.of(e.value)},
    null,
  );

  /// A versão mais nova pelo carimbo vence, como no servidor de verdade
  /// (ADR-024).
  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async {
    final id = '${card['id']}';
    final current = _cards[id];
    final stays = current == null ? null : CatalogVersion.of(current);
    if (CatalogVersion.of(card).replaces(stays)) _cards[id] = card;
    return null;
  }

  /// O cartão como desce, com o carimbo da versão que o servidor tem.
  static CardDefined _cardEvent(Map<String, Object?> payload) => CardDefined(
    id: 'card-remoto-${payload['id']}',
    card: CardCodec.decodeCard(payload),
    definedAt: CatalogVersion.definedAtOf(payload),
  );

  CreditCard? _cardOf(String id) => switch (_cards[id]) {
    final payload? => CardCodec.decodeCard(payload),
    _ => null,
  };

  @override
  Future<(RemoteIncome, ErrorCode?)> remoteIncome() async => (
    (receipts: _receipts.keys.toSet(), adjustments: _adjustments.keys.toSet()),
    null,
  );

  @override
  Future<ErrorCode?> sendIncome(Map<String, Object?> receipt) async {
    final decoded = IncomeCodec.decode(receipt);
    _receipts[decoded.id] = decoded;
    return null;
  }

  @override
  Future<ErrorCode?> sendVoucherAdjustment(
    Map<String, Object?> adjustment,
  ) async {
    final decoded = IncomeCodec.decodeAdjustment(adjustment, orElse: '?');
    _adjustments[decoded.id] = decoded;
    return null;
  }

  /// O plano mais novo pelo carimbo vence, como no servidor de verdade.
  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async {
    final incoming = MonthSetupCodec.decode(plan);
    if (!_plan.isNewerThan(incoming)) _plan = incoming;
    return null;
  }

  @override
  Future<(RemoteEntries, ErrorCode?)> remoteEntries() async => (
    (
      signatures: {
        for (final MapEntry(key: id, value: request) in _entries.entries)
          id: LedgerUplink.signatureOf(request),
      },
      revisedAt: {
        for (final MapEntry(key: id, value: request) in _entries.entries)
          id: ?request.revisedAt,
      },
      cancelled: Set.of(_cancelled),
    ),
    null,
  );

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async {
    final id = '${category['id']}';
    final current = categories[id];
    final stays = current == null ? null : CatalogVersion.of(current);
    if (CatalogVersion.of(category).replaces(stays)) categories[id] = category;
    return null;
  }

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    if (_cancelled.contains(entry.id)) return null;
    _entries[entry.id] = entry;
    return null;
  }

  /// A correção mais velha não apaga a mais nova, como no servidor de
  /// verdade (BL-062).
  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async {
    if (_cancelled.contains(entry.id)) return null;
    final current = _entries[entry.id];
    if (EditStamp.isNewer(current?.revisedAt, entry.revisedAt)) return null;
    _entries[entry.id] = entry;
    return null;
  }

  @override
  Future<ErrorCode?> cancelEntry(String id) async {
    _entries.remove(id);
    _cancelled.add(id);
    return null;
  }

  @override
  Future<(Set<String>, ErrorCode?)> remoteReversals() async =>
      (_reversals.keys.toSet(), null);

  @override
  Future<ErrorCode?> sendReversal(Map<String, Object?> reversal) async {
    _reversals['${reversal['id']}'] = reversal;
    return null;
  }

  final Map<String, DeviceFact> _facts = {};

  @override
  Future<(Set<String>, ErrorCode?)> remoteFacts() async =>
      (_facts.keys.toSet(), null);

  /// Lido pelo mesmo leitor estrito do servidor de verdade, e guardado na
  /// ordem de chegada.
  @override
  Future<ErrorCode?> sendFact(DeviceFact fact) async {
    final kept = DeviceFact.read(fact.toJson());
    _facts.putIfAbsent(kept.id, () => kept);
    return null;
  }

  List<Reversal> _reversalsOn(List<Entry> entries) {
    final byId = {for (final entry in entries) entry.id: entry};
    final reversals = <Reversal>[];
    for (final payload in _reversals.values) {
      final entry = byId['${payload['entryId']}'];
      if (entry == null) continue;
      final reversal = ReversalCodec.decode(
        payload,
        entry: entry,
        previous: reversals.where((r) => r.entryId == entry.id),
      ).valueOrNull;
      if (reversal != null) reversals.add(reversal);
    }
    return reversals;
  }

  @override
  Future<LedgerSnapshot?> snapshot() async {
    snapshots++;
    final base = DefaultCatalog.emptyBook;
    final entries = [
      for (final request in _entries.values)
        ?EntryCodec.toEntry(
          request,
          category: base.categoryOf(request.categoryId),
          cardOf: _cardOf,
          today: EntryCodec.parseDate(request.occurredOn).addDays(1),
        ).valueOrNull,
    ];
    final reversals = _reversalsOn(entries);
    return (
      events: [
        if (!_plan.isEmpty) PlanDefined(id: 'plan-remoto', setup: _plan),
        for (final receipt in _receipts.values) IncomeReceived(receipt),
        for (final adjustment in _adjustments.values)
          VoucherBalanceAdjusted(adjustment),
        for (final payload in _cards.values) _cardEvent(payload),
        for (final entry in entries) EntryRecorded(entry),
        for (final reversal in reversals) EntryReversed(reversal),
        for (final fact in _facts.values) ?DeviceFacts.toEvent(fact),
      ],
      cancelled: Set.of(_cancelled),
    );
  }
}
