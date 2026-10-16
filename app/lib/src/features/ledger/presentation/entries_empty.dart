import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A lista vazia, que diz **por que** está vazia e o que fazer.
///
/// São três vazios diferentes, e misturá-los engana: o mês de hoje sem nada
/// convida a lançar; um mês passado sem nada aponta o caminho de volta; e o
/// mês que tem lançamento, mas nenhum passa pelos filtros, diz qual filtro
/// tirar — "nada lançado" ali seria mentira.
class EntriesEmpty extends ConsumerWidget {
  /// Cria o vazio de [state].
  const new({required this.state, super.key});

  /// A tela pronta, sem lançamento nenhum na lista.
  final EntriesReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.read(entriesViewModelProvider.notifier);
    if (state.monthHasEntries && state.filter.isNarrowed) {
      return CajuiEmptyState(
        title: 'Nenhum lançamento com esses filtros',
        message: 'Tire ${_narrowings()} para ver mais.',
        action: CajuiNoticeAction(
          label: 'Tirar os filtros',
          onPressed: filters.clear,
        ),
      );
    }
    if (!state.isCurrentMonth) {
      return CajuiEmptyState(
        title: 'Nada lançado em ${DateLabels.month(state.month)}',
        message: 'As setas lá em cima levam aos outros meses.',
        action: CajuiNoticeAction(
          label: 'Voltar para ${_monthName(state.today.budgetMonth)}',
          onPressed: filters.currentMonth,
        ),
      );
    }
    return const CajuiEmptyState(
      title: 'Nada lançado ainda',
      message:
          'Fotografe o comprovante, escolha um print ou o PDF de um '
          'extrato da galeria, ou lance o primeiro à mão.',
    );
  }

  /// "setembro", sem o ano.
  static String _monthName(BudgetMonth month) =>
      DateLabels.month(month).split(' ').first;

  /// Os recortes em vigor, por nome: "a busca “mercado” ou a categoria
  /// Padaria". O mês não entra: ele tem lançamento, senão o vazio seria
  /// outro.
  String _narrowings() {
    final filter = state.filter;
    final text = filter.text.trim();
    final parts = [
      if (text.isNotEmpty) 'a busca “$text”',
      if (filter.categoryId != null)
        'a categoria ${state.categoryName ?? ''}'.trim(),
      if (filter.paymentMethodId != null)
        'a forma de pagamento ${state.paymentMethodName ?? ''}'.trim(),
    ];
    if (parts.length == 1) return parts.single;
    final last = parts.removeLast();
    return '${parts.join(', ')} ou $last';
  }
}
