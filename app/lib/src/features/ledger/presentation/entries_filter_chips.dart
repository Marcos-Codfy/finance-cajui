import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os filtros da lista, em chips.
///
/// Filtro escolhido é chip marcado, e um toque nele o tira. Categoria e
/// forma de pagamento sem escolha aparecem desmarcadas, com o nome do que
/// filtram: tocar abre a lista para escolher. Assim a mesma linha diz o que
/// está valendo e por onde se muda — sem um botão "Filtros" que esconde o
/// estado atrás de outra tela.
class EntriesFilterChips extends ConsumerWidget {
  /// Cria os chips dos filtros de [state].
  const new({required this.state, super.key});

  /// A tela pronta, com o filtro em vigor e o livro dos nomes.
  final EntriesReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.read(entriesViewModelProvider.notifier);
    final filter = state.filter;
    final text = filter.text.trim();
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        if (text.isNotEmpty) _on('“$text”', () => filters.search('')),
        if (filter.categoryId == null)
          _off('Categoria', () => _pickCategory(context, ref))
        else
          _on(
            state.categoryName ?? 'Categoria',
            () => filters.filterCategory(null),
          ),
        if (filter.paymentMethodId == null)
          _off('Forma de pagamento', () => _pickMethod(context, ref))
        else
          _on(
            state.paymentMethodName ?? 'Forma de pagamento',
            () => filters.filterPaymentMethod(null),
          ),
        if (!state.isCurrentMonth)
          _on(DateLabels.month(state.month), filters.currentMonth),
      ],
    );
  }

  /// Um filtro em vigor: marcado, e o toque o tira.
  static Widget _on(String label, VoidCallback remove) =>
      CajuiChip(label: label, selected: true, onSelected: (_) => remove());

  /// Um filtro ainda sem escolha: o toque abre a lista.
  static Widget _off(String label, VoidCallback pick) =>
      CajuiChip(label: label, selected: false, onSelected: (_) => pick());

  /// A escolha volta depois de outra tela: a lista pode ter fechado nesse
  /// meio-tempo, e aí não há filtro a mudar.
  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final picked = await OptionPickerPage.open<Category>(
      context,
      title: 'Categoria',
      options: state.book.categories,
      labelOf: (category) => category.name,
    );
    if (picked == null || !context.mounted) return;
    ref.read(entriesViewModelProvider.notifier).filterCategory(picked.id);
  }

  Future<void> _pickMethod(BuildContext context, WidgetRef ref) async {
    final picked = await OptionPickerPage.open<PaymentMethod>(
      context,
      title: 'Forma de pagamento',
      options: state.book.methods,
      labelOf: (method) => method.name,
    );
    if (picked == null || !context.mounted) return;
    ref.read(entriesViewModelProvider.notifier).filterPaymentMethod(picked.id);
  }
}
