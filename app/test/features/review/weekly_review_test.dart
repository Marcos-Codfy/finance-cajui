import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/review/application/weekly_review.dart';
import 'package:cajui/src/features/review/infrastructure/event_store_review_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';
import 'review_entries.dart';

void main() {
  final entries = [
    for (final event in reviewWeek) (event as EntryRecorded).entry,
  ];

  group('RN-870 · o que a revisão de domingo traz de volta', () {
    test('os últimos sete dias, em Outros ou lançados pela notificação', () {
      final waiting = WeeklyReview.of(
        entries,
        reviewed: const {},
        today: testToday,
      );

      expect(waiting.map((entry) => entry.id), ['auto', 'outros']);
    });

    test('o que já foi revisto não volta', () {
      final waiting = WeeklyReview.of(
        entries,
        reviewed: const {'auto'},
        today: testToday,
      );

      expect(waiting.map((entry) => entry.id), ['outros']);
    });

    test('a janela conta hoje e os seis dias antes: o sétimo dia atrás já '
        'ficou de fora', () {
      final edge = [
        reviewEntry('seis', categoryId: 'other', daysAgo: 6),
        reviewEntry('sete', categoryId: 'other', daysAgo: 7),
      ];

      final waiting = WeeklyReview.of(
        edge,
        reviewed: const {},
        today: testToday,
      );

      expect(waiting.map((entry) => entry.id), ['seis']);
    });
  });

  test('RN-871 · o revisto fica no registro do aparelho, num fato que o '
      'livro não lê', () async {
    final store = MemoryEventStore();
    final log = EventStoreReviewLog(store);

    await log.markReviewed(['a', 'b']);
    await log.markReviewed(['c']);
    await log.markReviewed(const []);

    expect(await log.reviewed(), {'a', 'b', 'c'});
    expect(store.events.map((event) => event.type).toSet(), {
      EventStoreReviewLog.done,
    });
    expect(store.events, hasLength(2), reason: 'lista vazia não grava nada');
  });
}
