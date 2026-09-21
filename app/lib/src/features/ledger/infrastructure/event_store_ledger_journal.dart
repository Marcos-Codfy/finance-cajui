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
    // Os fatos são lidos em ordem, e o cartão vem sempre antes da compra
    // feita nele: a compra parcelada recalcula as parcelas a partir do
    // cartão que já passou.
    final cards = <String, CreditCard>{};
    final events = <LedgerEvent>[];
    for (final stored in store.events) {
      final event = codec.decode(
        stored.id,
        stored.type,
        stored.payload,
        cardOf: (id) => cards[id],
      );
      if (event == null) continue;
      if (event is CardDefined) cards[event.card.id] = event.card;
      events.add(event);
    }
    return events;
  }

  @override
  Future<void> append(LedgerEvent event) async {
    final (:type, :payload) = codec.encode(event);
    await store.append(id: event.id, type: type, payload: payload);
  }
}
