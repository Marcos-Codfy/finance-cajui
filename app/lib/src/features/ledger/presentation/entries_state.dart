import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/open_failure.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
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

/// O livro abriu. [entries] pode estar vazio: mês sem lançamento não é erro.
final class EntriesReady extends EntriesState {
  /// Cria o estado com os lançamentos de [month].
  const new({
    required this.month,
    required this.today,
    required this.book,
    required this.entries,
    required this.spent,
    required this.voucher,
  });

  /// O mês à vista.
  final BudgetMonth month;

  /// O dia de hoje, para a tela dizer "hoje" e "ontem".
  final LocalDate today;

  /// O livro, de onde saem os nomes de categoria e de forma de pagamento.
  final LedgerBook book;

  /// Os lançamentos do mês, do mais recente para o mais antigo.
  final List<Entry> entries;

  /// O gasto do mês, por moeda — nunca somado (RN-111).
  final TenderAmounts spent;

  /// O vale do mês: o do plano, ou o crédito que entrou (RN-1006).
  final Money voucher;
}

/// O estado da tela de lançamentos, derivado do livro e do dia de hoje. É o
/// ViewModel desta tela: ela não tem ação própria além de abrir outras.
final entriesStateProvider = Provider<EntriesState>((ref) {
  final today = ref.watch(todayProvider);
  return switch (ref.watch(ledgerProvider)) {
    AsyncData(value: final book) => EntriesReady(
      month: today.budgetMonth,
      today: today,
      book: book,
      entries: book.entriesIn(today.budgetMonth),
      spent: book.spentIn(today.budgetMonth),
      voucher: BookFinances.of(book).voucherIn(today.budgetMonth),
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
