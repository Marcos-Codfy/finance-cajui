import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/statement_import.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que o lote gravou: os ids dos gastos e das entradas, para o desfazer;
/// as linhas que o domínio recusou, com o motivo; e quantas já estavam lá.
typedef StatementBatchOutcome = ({
  List<String> entries,
  List<String> incomes,
  Map<int, Failure> refused,
  int alreadyThere,
});

/// Grava e desfaz o extrato conferido com a Juju (RN-1115 a RN-1119).
///
/// Cada linha leva a chave pelo conteúdo (`StatementLineKey`): ler o mesmo
/// extrato de novo não lança em dobro, e lançar de novo depois de desfazer
/// grava com a tentativa seguinte, em vez de ser ignorado em silêncio.
class StatementBatch {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, o lançamento e o recebimento.
  final Ref ref;

  /// Quantas vezes a mesma linha tenta outra chave quando a gravação não
  /// aparece no livro — o desfazer feito no outro celular deixa a chave
  /// gasta sem que este saiba.
  static const _retries = 3;

  /// Grava as linhas [ready] de [lines], uma a uma. A que o domínio recusa
  /// fica de fora sem levar as outras (RN-1118).
  Future<StatementBatchOutcome> record(
    List<ResolvedLine> lines,
    List<int> ready,
  ) async {
    final keys = _keys(lines);
    final entries = <String>[];
    final incomes = <String>[];
    final refused = <int, Failure>{};
    var already = 0;
    for (final i in ready) {
      final result = await _one(lines[i], keys[i]);
      switch (result) {
        case _Recorded(:final id, :final income):
          (income ? incomes : entries).add(id);
        case _Refused(:final failure):
          refused[i] = failure;
        case _AlreadyThere():
          already++;
      }
    }
    return (
      entries: entries,
      incomes: incomes,
      refused: refused,
      alreadyThere: already,
    );
  }

  /// A chave de cada linha pelo conteúdo (RN-1117).
  static List<String> _keys(List<ResolvedLine> lines) => StatementLineKey.of([
    for (final line in lines)
      (
        on: line.line.occurredOn,
        amount: line.line.amount,
        merchantKey: line.merchantKey,
      ),
  ]);

  /// Desfaz o que [outcome] gravou, gastos e entradas (RN-1119, RN-1120).
  /// Devolve quantos foram desfeitos.
  Future<int> undo(StatementBatchOutcome outcome) async {
    final ledger = ref.read(ledgerProvider.notifier);
    for (final id in outcome.entries) {
      await ledger.cancel(id, reason: 'Desfeito na conversa do extrato');
    }
    final incomes = ref.read(incomeServiceProvider);
    for (final id in outcome.incomes) {
      await incomes.cancelIncome(id);
    }
    return outcome.entries.length + outcome.incomes.length;
  }

  Future<_LineResult> _one(ResolvedLine line, String base) async {
    var key = base;
    for (var attempt = 0; attempt < _retries; attempt++) {
      final book = await ref.read(ledgerProvider.future);
      final id = StatementLineKey.idFor(
        key,
        isKnown: (id) => _known(book, id, income: line.isIncome),
        isActive: (id) => _active(book, id, income: line.isIncome),
      );
      if (id.alreadyThere) return const _AlreadyThere();
      final failure = line.isIncome
          ? await _receive(id.id, line, book)
          : await _spend(id.id, line, book);
      if (failure != null) return _Refused(failure);
      final after = await ref.read(ledgerProvider.future);
      if (_active(after, id.id, income: line.isIncome)) {
        return _Recorded(id.id, income: line.isIncome);
      }
      // Gravou e não apareceu: a chave já tinha sido usada e desfeita noutro
      // lugar. A próxima volta passa por cima dela.
      key = '${id.id}-x';
    }
    return const _AlreadyThere();
  }

  static bool _known(LedgerBook book, String id, {required bool income}) =>
      income
      ? book.receipts.any((receipt) => receipt.id == id) ||
            book.cancelledReceiptIds.contains(id)
      : book.entryOf(id) != null || book.cancelledIds.contains(id);

  static bool _active(LedgerBook book, String id, {required bool income}) =>
      income
      ? book.receipts.any((receipt) => receipt.id == id)
      : book.entryOf(id) != null;

  Future<Failure?> _spend(String id, ResolvedLine line, LedgerBook book) async {
    final result = await ref
        .read(ledgerProvider.notifier)
        .record(
          EntryDraft(
            captureId: id,
            amountCents: line.line.amount.cents,
            description: line.line.description,
            occurredOn: line.line.occurredOn,
            category: book.categoriesById[line.line.categoryId],
            method: StatementImport.methodFor(line.line, book),
          ),
        );
    return result.failureOrNull;
  }

  Future<Failure?> _receive(
    String id,
    ResolvedLine line,
    LedgerBook book,
  ) async {
    await ref
        .read(incomeServiceProvider)
        .receiveIncome(
          tender: line.line.paymentKind?.tender ?? Tender.cash,
          amount: line.line.amount,
          receivedOn: line.line.occurredOn,
          salaryId: StatementImport.salaryOf(line.line, book)?.id,
          id: id,
        );
    return null;
  }
}

sealed class _LineResult {
  const new();
}

final class _Recorded extends _LineResult {
  const new(this.id, {required this.income});

  final String id;
  final bool income;
}

final class _Refused extends _LineResult {
  const new(this.failure);

  final Failure failure;
}

final class _AlreadyThere extends _LineResult {
  const new();
}

/// O caso de uso de gravar o extrato conferido.
final statementBatchProvider = Provider<StatementBatch>(StatementBatch.new);
