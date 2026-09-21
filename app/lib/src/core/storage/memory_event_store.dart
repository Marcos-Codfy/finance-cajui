import 'package:persistence/event_store.dart';

/// Um registro de eventos que vive só na memória: some quando o app fecha.
///
/// É o que a web usa — lá o Cajui é modo consulta, e guardar dado financeiro
/// no armazenamento do navegador seria deixá-lo ao alcance de qualquer
/// extensão (ADR-013). Serve também aos testes.
final class MemoryEventStore implements EventStore {
  final List<StoredEvent> _events = [];

  @override
  List<StoredEvent> get events => List.unmodifiable(_events);

  @override
  Future<StoredEvent> append({
    required String id,
    required String type,
    required Map<String, Object?> payload,
    int schema = 1,
  }) async {
    // O mesmo `id` duas vezes é a mesma gravação repetida, não outro fato.
    for (final known in _events) {
      if (known.id == id) return known;
    }
    final event = StoredEvent(
      seq: _events.length + 1,
      id: id,
      type: type,
      at: DateTime.now().toUtc(),
      schema: schema,
      payload: payload,
    );
    _events.add(event);
    return event;
  }

  @override
  Future<void> close() async {}
}
