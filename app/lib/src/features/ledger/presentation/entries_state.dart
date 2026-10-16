import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/open_failure.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/entry_filter.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Os estados da tela de lançamentos. A tela faz `switch` exaustivo sobre
/// eles (ADR-002).
@immutable
sealed class EntriesState {
  const new();
}

/// O livro ainda está sendo aberto.
final class EntriesLoading extends EntriesState {
  /// Cria o estado de carregamento.
  const new();
}

/// O livro não abriu.
final class EntriesFailed extends EntriesState {
  /// Cria o estado de falha, com o [code] que diz **por quê**.
  const new(this.code);

  /// O código do catálogo: cadeia quebrada, falta de espaço ou o genérico.
  final ErrorCode code;
}

/// O livro abriu. [entries] pode estar vazio: mês sem lançamento não é erro,
/// e filtro sem resultado também não.
final class EntriesReady extends EntriesState {
  /// Cria o estado com os lançamentos que passam por [filter].
  const new({
    required this.filter,
    required this.today,
    required this.book,
    required this.entries,
    required this.monthHasEntries,
    required this.spent,
    required this.voucher,
  });

  /// O que a pessoa pediu para ver: o mês e os recortes.
  final EntryFilter filter;

  /// O dia de hoje, para a tela dizer "hoje" e "ontem".
  final LocalDate today;

  /// O livro, de onde saem os nomes de categoria e de forma de pagamento.
  final LedgerBook book;

  /// Os lançamentos que passam pelo filtro, do mais recente para o mais
  /// antigo.
  final List<Entry> entries;

  /// Se o mês tem algum lançamento, com ou sem filtro. É o que separa "nada
  /// lançado ainda" de "nenhum lançamento com esses filtros": a primeira
  /// convida a lançar, a segunda diz o que tirar.
  final bool monthHasEntries;

  /// O gasto do mês, por moeda — nunca somado (RN-111). É o do mês inteiro,
  /// e não o da lista filtrada: o filtro escolhe o que se vê, não muda o
  /// quanto se gastou.
  final TenderAmounts spent;

  /// O vale do mês: o do plano, ou o crédito que entrou (RN-1006).
  final Money voucher;

  /// O mês à vista.
  BudgetMonth get month => filter.month;

  /// Se o mês à vista é o de hoje.
  bool get isCurrentMonth => month == today.budgetMonth;

  /// O nome da categoria do filtro, ou `null` sem filtro de categoria.
  String? get categoryName => book.categories
      .where((category) => category.id == filter.categoryId)
      .firstOrNull
      ?.name;

  /// O nome da forma de pagamento do filtro, ou `null` sem esse filtro.
  String? get paymentMethodName => book.methods
      .where((method) => method.id == filter.paymentMethodId)
      .firstOrNull
      ?.name;
}

/// O estado da tela de lançamentos, derivado do livro, do dia de hoje e dos
/// filtros do [entriesViewModelProvider]. Descartado com a tela, como eles.
final Provider<EntriesState> entriesStateProvider = Provider.autoDispose((ref) {
  final today = ref.watch(todayProvider);
  final filter = ref.watch(entriesViewModelProvider);
  return switch (ref.watch(ledgerProvider)) {
    AsyncData(value: final book) => EntriesReady(
      filter: filter,
      today: today,
      book: book,
      entries: filter.apply(book.entries),
      monthHasEntries: book.entriesIn(filter.month).isNotEmpty,
      spent: book.spentIn(filter.month),
      voucher: BookFinances.of(book).voucherIn(filter.month),
    ),
    // `hasError`, e **não** `AsyncError()`: quando o livro não abre, o
    // Riverpod deixa o estado em `AsyncLoading` carregando o erro junto, e
    // não em `AsyncError`. Casando só pelo tipo, a tela ficava no esqueleto
    // de carregamento **para sempre** — o estado de falha nunca chegava, e
    // por isso ninguém tinha visto que o erro era genérico (BL-033).
    AsyncValue(hasError: true, :final error) => EntriesFailed(
      OpenFailure.codeOf(error),
    ),
    _ => const EntriesLoading(),
  };
});
