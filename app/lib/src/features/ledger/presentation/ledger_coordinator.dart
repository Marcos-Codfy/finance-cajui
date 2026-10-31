import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/entry_detail_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/installments_picker.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:cajui/src/features/ledger/presentation/reversal_page.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde levam as telas dos lançamentos (ADR-031).
///
/// A tela diz o que aconteceu ("tocou na linha"); quem decide qual cena abrir,
/// e com que dados, é este coordinator. Ele também monta a cena: é a "factory
/// de cena" desta feature, e as dependências de cada cena vêm do provider do
/// ViewModel dela (ADR-032).
final class LedgerCoordinator {
  /// Cria o coordinator sobre o navegador de cenas. O `ref` só serve para
  /// pré-filtrar a lista de lançamentos ao abri-la.
  const new(this._navigator, this._ref);

  final SceneNavigator _navigator;
  final Ref _ref;

  /// Os lançamentos do mês. Com [categoryId] e [month], já abre filtrada: é o
  /// que o anel do Meu mês faz ao tocar uma categoria.
  Future<void> openEntries({String? categoryId, BudgetMonth? month}) {
    final shown = _navigator.push<void>(const EntriesPage());
    if (categoryId != null || month != null) {
      // Depois do primeiro quadro a tela já existe, e o filtro dela também.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final filters = _ref.read(entriesViewModelProvider.notifier);
        if (month != null) filters.showMonth(month);
        if (categoryId != null) filters.filterCategory(categoryId);
      });
    }
    return shown;
  }

  /// O detalhe do lançamento [entryId].
  Future<void> openEntry(String entryId) =>
      _navigator.push<void>(EntryDetailPage(entryId: entryId));

  /// A correção de [entry]: o formulário de lançar inteiro — mesmos campos,
  /// mesmas regras, mesmos erros — aberto com o que já está gravado. É daqui
  /// e do deslizar da lista. O rascunho entra por um escopo próprio, para a
  /// correção não sujar o formulário de um lançamento novo.
  Future<void> openCorrection(LedgerBook book, Entry entry) {
    final draft = EntryDraft.correcting(
      entry,
      category: book.categoryOf(entry.categoryId),
      methodOf: book.methodOf,
    );
    return _navigator.push<void>(
      ProviderScope(
        overrides: [initialDraftProvider.overrideWithValue(draft)],
        child: const EntryFormPage(
          title: 'Corrigir lançamento',
          submitLabel: 'Guardar correção',
        ),
      ),
    );
  }

  /// O formulário de lançar à mão.
  Future<void> openEntryForm() => _navigator.push<void>(const EntryFormPage());

  /// O estorno de [entry].
  Future<void> openReversal(Entry entry) =>
      _navigator.push<void>(ReversalPage(entry: entry));

  /// Uma escolha curta num painel que sobe de baixo: devolve a opção, ou
  /// `null` se a pessoa desistiu.
  Future<T?> pick<T>({
    required String title,
    required List<T> options,
    required String Function(T option) labelOf,
    T? selected,
  }) => _navigator.pushSheet<T>(
    OptionPickerPage<T>(
      title: title,
      options: options,
      labelOf: labelOf,
      selected: selected,
    ),
  );

  /// Em quantas vezes foi a compra de [total], com [selected] marcado.
  Future<int?> pickInstallments({required Money total, required int selected}) {
    return pick<int>(
      title: 'Em quantas vezes',
      options: InstallmentsPicker.options,
      labelOf: (count) => InstallmentsPicker.label(count, total),
      selected: selected,
    );
  }

  /// Fecha a escolha ou a tela atual devolvendo [result].
  void close([Object? result]) => _navigator.pop(result);
}

/// O coordinator dos lançamentos.
final ledgerCoordinatorProvider = Provider<LedgerCoordinator>(
  (ref) => LedgerCoordinator(ref.watch(sceneNavigatorProvider), ref),
);
