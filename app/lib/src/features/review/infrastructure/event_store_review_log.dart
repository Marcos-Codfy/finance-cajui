import 'package:cajui/src/features/review/application/review_log.dart';
import 'package:persistence/event_store.dart';

/// O que já foi revisto, no mesmo registro cifrado do aparelho (RN-871).
///
/// O tipo `review.done` não é fato do livro: o leitor do livro o ignora, e
/// a sincronização só sobe fatos do livro. Por isso ele nunca sai daqui.
final class EventStoreReviewLog implements ReviewLog {
  /// Cria o registro sobre [_store].
  const new(this._store);

  final EventStore _store;

  /// O tipo do evento "revisto".
  static const done = 'review.done';

  @override
  Future<Set<String>> reviewed() async => {
    for (final event in _store.events)
      if (event.type == done)
        for (final id in event.payload['ids'] as List? ?? const [])
          if (id is String) id,
  };

  /// A chave é o tamanho do registro, como nas preferências: dois toques
  /// seguidos não podem gerar a mesma chave e sumir como repetição.
  @override
  Future<void> markReviewed(Iterable<String> entryIds) async {
    final ids = entryIds.toList();
    if (ids.isEmpty) return;
    await _store.append(
      id: 'review-done-${_store.events.length}',
      type: done,
      payload: {'ids': ids},
    );
  }
}
