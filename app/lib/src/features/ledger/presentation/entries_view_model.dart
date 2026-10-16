import 'package:cajui/src/features/ledger/application/entry_filter.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da tela de lançamentos (ADR-002): guarda os filtros que a
/// pessoa escolheu. Quem decide o que passa por eles é o [EntryFilter]; a
/// lista e o gasto do mês saem do `entriesStateProvider`.
class EntriesViewModel extends Notifier<EntryFilter> {
  /// A tela abre no mês de hoje, sem recorte nenhum.
  ///
  /// O dia é lido, e não observado: virar o dia com a tela aberta não pode
  /// apagar a busca que a pessoa está digitando.
  @override
  EntryFilter build() =>
      EntryFilter(month: ref.read(todayProvider).budgetMonth);

  /// Busca [text] na descrição.
  void search(String text) => state = state.withText(text);

  /// Vai para o mês anterior, mantendo os outros recortes.
  void previousMonth() => state = state.withMonth(state.month.previous);

  /// Vai para o mês seguinte. Não passa do mês de hoje: lançamento nunca é
  /// do futuro (RN-206), então lá só haveria lista vazia.
  void nextMonth() {
    if (!state.month.isBefore(ref.read(todayProvider).budgetMonth)) return;
    state = state.withMonth(state.month.next);
  }

  /// Volta para o mês de hoje.
  void currentMonth() =>
      state = state.withMonth(ref.read(todayProvider).budgetMonth);

  /// Mostra só a categoria [id]; `null` volta a todas.
  void filterCategory(String? id) => state = state.withCategory(id);

  /// Mostra só o que foi pago por [id]; `null` volta a todas.
  void filterPaymentMethod(String? id) => state = state.withPaymentMethod(id);

  /// Tira a busca, a categoria e a forma de pagamento; o mês fica.
  void clear() => state = state.cleared;
}

/// Os filtros da tela de lançamentos. Descartados ao fechar a tela: quem
/// volta a ela vê o mês de hoje inteiro, e não um recorte esquecido.
final NotifierProvider<EntriesViewModel, EntryFilter> entriesViewModelProvider =
    NotifierProvider.autoDispose(EntriesViewModel.new);
