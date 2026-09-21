import 'package:cajui/src/core/feedback/sound_player_provider.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:cajui/src/features/receipts/application/receipt_inbox.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:cajui/src/features/receipts/infrastructure/event_store_capture_shelf.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_inbox.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_reader.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:persistence/event_store.dart';

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
}

/// As trocas que todo teste do app faz: som mudo, livro na memória, dia fixo,
/// identificadores em sequência (`id-0`, `id-1`…) e nenhuma captura chegando
/// — a não ser que o teste passe [inbox] e [reader].
List<Override> testOverrides({
  LedgerJournal? journal,
  MutePlayer? player,
  LocalDate? today,
  ReceiptInbox? inbox,
  ReceiptReader? reader,
  EventStore? captureStore,
}) {
  var next = 0;
  return [
    soundPlayerProvider.overrideWithValue(player ?? MutePlayer()),
    ledgerJournalProvider.overrideWithValue(journal ?? MemoryLedgerJournal()),
    clockProvider.overrideWithValue(FixedClock(today ?? testToday)),
    newIdProvider.overrideWithValue(() => 'id-${next++}'),
    receiptInboxProvider.overrideWithValue(inbox ?? const NoReceiptInbox()),
    receiptReaderProvider.overrideWithValue(reader ?? const NoReceiptReader()),
    captureShelfProvider.overrideWithValue(
      EventStoreCaptureShelf(captureStore ?? MemoryEventStore()),
    ),
  ];
}
