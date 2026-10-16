import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/entry_days.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_detail_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_row.dart';
import 'package:cajui/src/features/ledger/presentation/pending_cancels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os lançamentos do mês agrupados por dia, com o total de cada dia, e cada
/// linha deslizável: para a direita corrige, para a esquerda cancela — com
/// Desfazer enquanto a janela está aberta (17/10/2026).
class EntriesDayList extends ConsumerWidget {
  /// Cria a lista de [state].
  const new({required this.state, super.key});

  /// A tela pronta, com os lançamentos já filtrados.
  final EntriesReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(pendingCancelsProvider);
    final days = EntryDays.of([
      for (final entry in state.entries)
        if (!hidden.contains(entry.id)) entry,
    ]);
    final order = {
      for (final (index, entry) in state.entries.indexed) entry.id: index,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hidden.isNotEmpty) _undo(ref, hidden),
        for (final day in days) ...[
          _header(context, day),
          for (final entry in day.entries)
            CajuiEntrance(
              key: ValueKey(entry.id),
              index: order[entry.id] ?? 0,
              child: _row(context, ref, entry),
            ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Entry entry) =>
      CajuiSwipeRow(
        id: entry.id,
        startLabel: 'Corrigir',
        onStart: () => EntryDetailPage.correct(context, state.book, entry),
        endLabel: 'Cancelar',
        onEnd: () => ref.read(pendingCancelsProvider.notifier).hide(entry.id),
        child: EntryRow(entry: entry, book: state.book, today: state.today),
      );

  /// "Hoje · R$ 86,00 · vale R$ 20,00": o vale ao lado, nunca somado.
  Widget _header(BuildContext context, EntryDay day) {
    final theme = CajuiTheme.of(context);
    final cash = BrlFormatter.format(day.spent.cash.cents);
    final voucher = day.spent.mealVoucher;
    final label = DateLabels.day(day.day, today: state.today);
    final words = [
      // Cabeçalho começa em maiúscula: "Ontem", "Sáb., 19 de set.".
      label[0].toUpperCase() + label.substring(1),
      cash,
      if (voucher.isPositive) 'vale ${BrlFormatter.format(voucher.cents)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(
        top: CajuiSpacing.lg,
        bottom: CajuiSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          words,
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
      ),
    );
  }

  /// A barra do Desfazer, enquanto há cancelamento esperando.
  static Widget _undo(WidgetRef ref, Set<String> hidden) => Row(
    children: [
      Expanded(
        child: Text(
          hidden.length == 1
              ? 'Lançamento cancelado'
              : '${hidden.length} lançamentos cancelados',
        ),
      ),
      CajuiButton(
        label: 'Desfazer',
        variant: CajuiButtonVariant.ghost,
        onPressed: () =>
            [...hidden]
                .forEach(ref.read(pendingCancelsProvider.notifier).restore),
      ),
    ],
  );
}
