import 'package:cajui/src/features/ledger/application/frequent_spends.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Gastos de sempre": os lançamentos que se repetem, em chips, no alto do
/// "Novo gasto". Um toque preenche o formulário inteiro com o da última
/// vez, e a pessoa só confere o valor (27/11/2026, heurística de
/// flexibilidade e eficiência).
///
/// Sem histórico, não aparece: uma seção vazia só ocuparia lugar.
class FrequentSpendsRow extends ConsumerWidget {
  /// Cria a linha, que muda o formulário por [edit].
  const new({required this.edit, super.key});

  /// Troca o rascunho por iniciativa do app, refazendo os campos.
  final EntryFormEdit edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spends = ref.watch(frequentSpendsProvider);
    final book = ref.watch(ledgerProvider).value;
    if (spends.isEmpty || book == null) return const SizedBox.shrink();
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spends.first.count > 1 ? 'Gastos de sempre' : 'Repetir o último',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        _chips(spends, book),
      ],
    );
  }

  Widget _chips(List<FrequentSpend> spends, LedgerBook book) => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final spend in spends)
        CajuiChip(
          label: _label(spend),
          selected: false,
          onSelected: (_) =>
              edit((draft) => FrequentSpends.repeat(draft, spend, book)),
        ),
    ],
  );

  /// "Padaria Central · R$ 12,50".
  static String _label(FrequentSpend spend) =>
      '${spend.description} · ${BrlFormatter.format(spend.amount.cents)}';
}
