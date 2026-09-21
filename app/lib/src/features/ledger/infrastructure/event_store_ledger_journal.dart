import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:persistence/event_store.dart';

/// O livro gravado no registro de eventos do aparelho — o mesmo formato do
/// servidor: linhas cifradas uma a uma e encadeadas (ADR-004 e ADR-005).
final class EventStoreLedgerJournal implements LedgerJournal {
  /// Cria o livro sobre o registro [store].
  const new({required this.store, required this.codec});

  /// O registro de eventos.
  final EventStore store;

  /// A conversão entre fato e evento gravado.
  final LedgerEventCodec codec;

  @override
  Future<List<LedgerEvent>> readAll() async {
    // Os fatos são lidos em ordem, e o que um fato precisa vem sempre antes
    // dele: o cartão antes da compra parcelada, que recalcula as parcelas a
    // partir dele; o lançamento antes do estorno que se liga a ele.
    final cards = <String, CreditCard>{};
    final entries = <String, Entry>{};
    final events = <LedgerEvent>[];
    for (final stored in store.events) {
      final event = codec.decode(
        stored.id,
        stored.type,
        stored.payload,
        cardOf: (id) => cards[id],
        entryOf: (id) => entries[id],
      );
      if (event == null) continue;
      _remember(event, cards, entries);
      events.add(event);
    }
    return events;
  }

  static void _remember(
    LedgerEvent event,
    Map<String, CreditCard> cards,
    Map<String, Entry> entries,
  ) {
    switch (event) {
      case CardDefined(:final card):
        cards[card.id] = card;
      case EntryRecorded(:final entry) || EntryCorrected(:final entry):
        entries[entry.id] = entry;
      case EntryCancelled(:final entryId):
        entries.remove(entryId);
      default:
    }
  }

  @override
  Future<void> append(LedgerEvent event) async {
    final (:type, :payload) = codec.encode(event);
    await store.append(id: event.id, type: type, payload: payload);
  }
}
