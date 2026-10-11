import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/draft_defaults.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:cajui/src/features/review/presentation/review_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da revisão da semana (RN-871): trocar a categoria de um
/// gasto em um toque, ou dizer que está tudo certo.
class ReviewViewModel extends Notifier<ReviewState> {
  @override
  ReviewState build() {
    final book = ref.watch(ledgerProvider).value;
    final reviewed = ref.watch(reviewedEntriesProvider);
    if (book == null || !reviewed.hasValue) return const ReviewLoading();
    final items = ref.watch(reviewItemsProvider);
    if (items.isEmpty) return const ReviewClear();
    return ReviewPending(items: items, categories: _choices(book));
  }

  /// As categorias de gasto do dia a dia e as assinaturas, menos Outros —
  /// que é o que se está tirando. A assinatura chega pela notificação como
  /// qualquer compra ("Netflix R$ 39,90"), e tirá-la do dia a dia a põe no
  /// grupo certo do mês (RN-1003). Fixos e dívidas ficam de fora.
  static List<Category> _choices(LedgerBook book) => [
    for (final category in book.categories)
      if (_reviewable.contains(category.block) &&
          category.id != DraftDefaults.fallbackCategoryId)
        category,
  ];

  static const Set<Block> _reviewable = {Block.variable, Block.subscription};

  /// Põe [entry] em [category]. É uma correção como outra qualquer
  /// (RN-208): o original fica no registro. Tocar na categoria que ele já
  /// tem confirma, sem gravar fato nenhum. Nos dois casos, ele sai da lista.
  Future<void> choose(Entry entry, Category category) async {
    final book = await ref.read(ledgerProvider.future);
    final draft = EntryDraft.correcting(
      entry,
      category: category,
      methodOf: book.methodOf,
    );
    final result = await ref.read(ledgerProvider.notifier).correct(draft);
    if (result.failureOrNull case final failure?) {
      final current = state;
      if (current is ReviewPending) {
        state = ReviewPending(
          items: current.items,
          categories: current.categories,
          error: FailurePresenter.present(failure),
        );
      }
      return;
    }
    await _mark([entry.id]);
  }

  /// "Está tudo certo": o que sobrou na lista fica como está, e sai dela.
  Future<void> allGood() async {
    await _mark([for (final entry in ref.read(reviewItemsProvider)) entry.id]);
  }

  Future<void> _mark(Iterable<String> ids) async {
    await ref.read(reviewLogProvider).markReviewed(ids);
    ref.invalidate(reviewedEntriesProvider);
    await ref.read(reviewedEntriesProvider.future);
  }
}

/// A revisão da semana.
final reviewProvider = NotifierProvider<ReviewViewModel, ReviewState>(
  ReviewViewModel.new,
);
