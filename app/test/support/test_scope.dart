import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/feedback/sound_player_provider.dart';
import 'package:cajui/src/core/settings/no_preferences_store.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/no_speech_input.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/receipts/application/receipt_inbox.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:cajui/src/features/receipts/infrastructure/event_store_capture_shelf.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_inbox.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_reader.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:persistence/event_store.dart';

import 'memory_ledger_journal.dart';
import 'mute_player.dart';

/// O dia em que os testes acontecem: domingo, 20 de setembro de 2026.
final testToday = LocalDate(2026, 9, 20);

/// Um relógio parado em [day].
class FixedClock implements Clock {
  /// Cria o relógio.
  const new(this.day);

  /// O dia que ele sempre responde.
  final LocalDate day;

  @override
  LocalDate today() => day;

  @override
  DateTime now() => DateTime.utc(day.year, day.month, day.day, 12);
}

/// As trocas que todo teste do app faz: som mudo, livro na memória, dia fixo,
/// identificadores em sequência (`id-0`, `id-1`…) e nenhuma captura chegando
/// — a não ser que o teste passe [inbox] e [reader]. [idPrefix] troca o
/// começo dos identificadores: dois aparelhos no mesmo teste não podem
/// gerar os mesmos.
List<Override> testOverrides({
  LedgerJournal? journal,
  MutePlayer? player,
  LocalDate? today,
  ReceiptInbox? inbox,
  ReceiptReader? reader,
  EventStore? captureStore,
  AssistantGateway? assistant,
  PreferencesStore? preferences,
  LedgerUplink? uplink,
  LedgerDownlink? downlink,
  String idPrefix = 'id',
}) {
  var next = 0;
  return [
    soundPlayerProvider.overrideWithValue(player ?? MutePlayer()),
    ledgerJournalProvider.overrideWithValue(journal ?? MemoryLedgerJournal()),
    clockProvider.overrideWithValue(FixedClock(today ?? testToday)),
    newIdProvider.overrideWithValue(() => '$idPrefix-${next++}'),
    ..._capture(inbox, reader, captureStore),
    assistantGatewayProvider.overrideWithValue(
      assistant ?? const _SilentGateway(),
    ),
    ..._server(uplink, downlink),
    speechInputProvider.overrideWithValue(const NoSpeechInput()),
    ..._extras(preferences),
  ];
}

/// O servidor: o teste roda como celular cadastrado — é lá que a camada
/// local responde —, e o livro não sobe nem desce de lugar nenhum, a não
/// ser que o teste mande.
List<Override> _server(LedgerUplink? uplink, LedgerDownlink? downlink) => [
  ledgerUplinkProvider.overrideWithValue(uplink ?? const _PairedUplink()),
  ledgerDownlinkProvider.overrideWithValue(downlink ?? const _NoDownlink()),
];

/// A captura: nada chega, a não ser que o teste mande.
List<Override> _capture(
  ReceiptInbox? inbox,
  ReceiptReader? reader,
  EventStore? captureStore,
) => [
  receiptInboxProvider.overrideWithValue(inbox ?? const NoReceiptInbox()),
  receiptReaderProvider.overrideWithValue(reader ?? const NoReceiptReader()),
  captureShelfProvider.overrideWithValue(
    EventStoreCaptureShelf(captureStore ?? MemoryEventStore()),
  ),
];

/// As trocas que nasceram depois e não cabem na lista principal sem
/// estourar o limite de linhas.
///
/// As preferências do teste começam sempre no padrão, e não sobrevivem
/// entre um teste e outro: teste que herda escolha de outro mente.
List<Override> _extras(PreferencesStore? preferences) => [
  preferencesStoreProvider.overrideWithValue(
    preferences ?? const NoPreferencesStore(),
  ),
];

/// Uma subida que diz "este aparelho tem livro próprio": é o celular
/// cadastrado, onde a camada local de respostas vale. Não manda nada.
final class _PairedUplink implements LedgerUplink {
  const new();

  @override
  bool get isPaired => true;

  /// Sem sessão aberta: o teste de tela não sobe nada sozinho, e continua
  /// medindo só o que a tela faz.
  @override
  bool get hasOpenSession => false;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async =>
      (const <String>{}, null);

  @override
  Future<(Set<String>, ErrorCode?)> remoteCards() async =>
      (const <String>{}, null);

  @override
  Future<(RemoteEntries, ErrorCode?)> remoteEntries() async => (
    (
      signatures: const <String, String>{},
      revisedAt: const <String, DateTime>{},
      cancelled: const <String>{},
    ),
    null,
  );

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async => null;

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async => null;

  @override
  Future<(RemoteIncome, ErrorCode?)> remoteIncome() async =>
      ((receipts: const <String>{}, adjustments: const <String>{}), null);

  @override
  Future<ErrorCode?> sendIncome(Map<String, Object?> receipt) async => null;

  @override
  Future<ErrorCode?> sendVoucherAdjustment(
    Map<String, Object?> adjustment,
  ) async => null;

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async => null;

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async => null;

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async => null;

  @override
  Future<(Set<String>, ErrorCode?)> remoteReversals() async =>
      (const <String>{}, null);

  @override
  Future<ErrorCode?> sendReversal(Map<String, Object?> reversal) async => null;

  @override
  Future<ErrorCode?> cancelEntry(String id) async => null;
}

/// Uma descida que nunca tem nada: o teste de tela mede o que a tela faz,
/// e não o que outro aparelho fez.
final class _NoDownlink implements LedgerDownlink {
  const new();

  @override
  Future<LedgerSnapshot?> snapshot() async => null;
}

/// Um assistente que nunca foi pareado. Vive aqui, e não em `lib/`: é dublê
/// de teste, e código que só o teste usa não tem por que viajar no APK.
final class _SilentGateway implements AssistantGateway {
  const new();

  @override
  bool get isPaired => false;

  @override
  Future<AssistantReply> ask(String message) async =>
      const AssistantNotPaired();
}
