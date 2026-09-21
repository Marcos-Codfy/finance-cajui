import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/capture_shelf.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:domain/domain.dart';
import 'package:persistence/event_store.dart';

/// As capturas pendentes e as regras aprendidas, guardadas no mesmo registro
/// cifrado dos lançamentos (ADR-004 e ADR-005).
///
/// O texto de um comprovante tem nome, valor e lugar: é dado financeiro, e
/// fica em repouso com a mesma proteção de um lançamento (T-07).
final class EventStoreCaptureShelf implements CaptureShelf {
  /// Cria a prateleira sobre o registro [store].
  const new(this.store);

  /// O registro de eventos.
  final EventStore store;

  static const _deferred = 'capture.deferred';
  static const _closed = 'capture.closed';
  static const _learned = 'capture.rule-learned';

  @override
  Future<List<PendingCapture>> pending() async {
    final open = <String, PendingCapture>{};
    for (final event in store.events) {
      final id = event.payload['id'] as String?;
      if (event.type == _deferred && id != null) open[id] = _read(event);
      if (event.type == _closed) open.remove(id);
    }
    return open.values.toList();
  }

  PendingCapture _read(StoredEvent event) => PendingCapture(
    id: event.payload['id']! as String,
    receivedOn: EntryCodec.parseDate(event.payload['receivedOn']! as String),
    text: event.payload['text']! as String,
    filePath: event.payload['filePath'] as String?,
  );

  @override
  Future<void> defer(PendingCapture capture) => store.append(
    id: 'capture-deferred-${capture.id}',
    type: _deferred,
    payload: {
      'id': capture.id,
      'receivedOn': '${capture.receivedOn}',
      'text': capture.text,
      'filePath': capture.filePath,
    },
  );

  @override
  Future<void> close(String id) async {
    final isOpen = (await pending()).any((capture) => capture.id == id);
    if (!isOpen) return;
    await store.append(
      id: 'capture-closed-$id',
      type: _closed,
      payload: {'id': id},
    );
  }

  @override
  Future<Map<String, String>> learnedRules() async => {
    for (final event in store.events)
      if (event.type == _learned)
        event.payload['merchant']! as String:
            event.payload['categoryId']! as String,
  };

  @override
  Future<void> learn({
    required String merchant,
    required String categoryId,
  }) async {
    // A mesma chave que o classificador usa para procurar a regra.
    final key = PossibleDuplicate.normalize(merchant);
    if (key.isEmpty) return;
    await store.append(
      // O número de ordem entra no identificador: reaprender o mesmo
      // estabelecimento é um fato novo, que troca a regra anterior.
      id: 'capture-rule-${store.events.length + 1}',
      type: _learned,
      payload: {'merchant': key, 'categoryId': categoryId},
    );
  }
}
