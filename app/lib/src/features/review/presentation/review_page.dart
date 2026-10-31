import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/review/presentation/review_entry_card.dart';
import 'package:cajui/src/features/review/presentation/review_state.dart';
import 'package:cajui/src/features/review/presentation/review_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A revisão da semana (RN-871): o que ficou em Outros e o que o Cajui
/// lançou sozinho, com a categoria certa a um toque.
///
/// Abre pelo aviso de domingo. A promessa do aviso é "um minuto", e a tela
/// a cumpre: uma lista, um toque por gasto, um botão para o resto.
class ReviewPage extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewProvider);
    return CajuiScreen(
      title: 'Revisão da semana',
      onBack: context.back,
      footer: state is ReviewPending ? _allGood(context, ref) : null,
      children: switch (state) {
        ReviewLoading() => const [],
        ReviewClear() => const [
          CajuiEmptyState(
            title: 'Tudo revisto',
            message:
                'Nenhum gasto da semana ficou para conferir. Até o '
                'próximo domingo.',
          ),
        ],
        ReviewPending() => _pending(context, ref, state),
      },
    );
  }

  List<Widget> _pending(
    BuildContext context,
    WidgetRef ref,
    ReviewPending state,
  ) {
    final book = ref.watch(ledgerProvider).value;
    final today = ref.watch(todayProvider);
    final error = state.error;
    return [
      _introText(context, state.items.length),
      if (error != null) ...[
        const SizedBox(height: CajuiSpacing.lg),
        ErrorNotice(error: error, onAction: (_) {}),
      ],
      for (final entry in state.items) ...[
        const SizedBox(height: CajuiSpacing.lg),
        ReviewEntryCard(
          key: ValueKey(entry.id),
          entry: entry,
          categoryName: _nameOf(book, entry),
          categories: state.categories,
          today: today,
          onChoose: (category) => _choose(context, ref, entry, category),
        ),
      ],
    ];
  }

  static Widget _introText(BuildContext context, int count) {
    final theme = CajuiTheme.of(context);
    return Text(
      _intro(count),
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  static String _intro(int count) => count == 1
      ? 'Um gasto da semana pede um olhar. Toque na categoria certa; se já '
            'estiver certa, toque nela para confirmar.'
      : '$count gastos da semana pedem um olhar. Toque na categoria certa '
            'de cada um; se já estiver certa, toque nela para confirmar.';

  static String _nameOf(LedgerBook? book, Entry entry) =>
      book?.categoryOf(entry.categoryId).name ?? '';

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    Entry entry,
    Category category,
  ) async {
    final feedback = CajuiFeedbackScope.of(context);
    await ref.read(reviewProvider.notifier).choose(entry, category);
    feedback.saved();
  }

  Widget _allGood(BuildContext context, WidgetRef ref) => CajuiButton(
    label: 'Está tudo certo',
    expand: true,
    onPressed: () async {
      final navigator = context.navigator;
      final feedback = CajuiFeedbackScope.of(context);
      await ref.read(reviewProvider.notifier).allGood();
      feedback.saved();
      navigator.pop();
    },
  );
}
