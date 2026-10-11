import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/review/application/review_log.dart';
import 'package:cajui/src/features/review/application/weekly_review.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onde fica o que já foi revisto. A raiz do app liga ao registro do
/// aparelho; sem ligação, vale a memória — o teste que não fala disso.
final reviewLogProvider = Provider<ReviewLog>((ref) => _MemoryReviewLog());

/// Os lançamentos já revistos. Quem marca algum o invalida.
final reviewedEntriesProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(reviewLogProvider).reviewed(),
);

/// O que espera a revisão da semana hoje (RN-870), os mais recentes
/// primeiro. Vazio enquanto o livro abre.
final reviewItemsProvider = Provider<List<Entry>>((ref) {
  final book = ref.watch(ledgerProvider).value;
  final reviewed = ref.watch(reviewedEntriesProvider).value;
  if (book == null || reviewed == null) return const [];
  return WeeklyReview.of(
    book.entries,
    reviewed: reviewed,
    today: ref.watch(clockProvider).today(),
  );
});

final class _MemoryReviewLog implements ReviewLog {
  final _ids = <String>{};

  @override
  Future<Set<String>> reviewed() async => Set.unmodifiable(_ids);

  @override
  Future<void> markReviewed(Iterable<String> entryIds) async =>
      _ids.addAll(entryIds);
}
