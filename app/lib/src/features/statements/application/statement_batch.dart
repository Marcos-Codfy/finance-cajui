import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/statement_import.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que o lote gravou: os ids dos gastos e das entradas, para o desfazer;
/// as linhas que o domínio recusou, com o motivo; quantas já estavam lá; e
/// o erro que parou o lote no meio, quando parou.
typedef StatementBatchOutcome = ({
  List<String> entries,
  List<String> incomes,
  Map<int, Failure> refused,
  int alreadyThere,
  ErrorCode? stopped,
});

/// Grava e desfaz o extrato conferido com a Juju (RN-1115 a RN-1120).
///
/// Cada linha leva a chave pelo conteúdo (`StatementLineKey`) mais o
/// carimbo desta leitura: ler de novo não lança em dobro, e lançar de novo
/// depois de desfazer grava com um id que nunca foi desfeito em lugar
/// nenhum.
class StatementBatch {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, o lançamento e o recebimento.
  final Ref ref;

  /// Grava as linhas [ready] de [lines], com o carimbo [launch]. As compras
  /// no cartão vão para [cardId] quando a pessoa escolheu. A linha que o
  /// domínio recusa fica de fora sem levar as outras (RN-1118); uma falha
  /// de gravação para o lote, e o que já entrou volta para o desfazer.
  Future<StatementBatchOutcome> record(
    List<ResolvedLine> lines,
    List<int> ready, {
    required String launch,
    String? cardId,
  }) async {
    final keys = _keys(lines);
    final active = _activeIds(await ref.read(ledgerProvider.future));
    final batch = _Batch();
    for (final i in ready) {
      final id = StatementLineKey.idFor(
        keys[i],
        launch: launch,
        activeIds: active,
      );
      if (id.alreadyThere) {
        batch.already++;
        continue;
      }
      try {
        batch.add(i, lines[i], id.id, await _one(lines[i], id.id, cardId));
      } on Exception {
        return batch.outcome(ErrorCode.app01);
      }
    }
    return batch.outcome(null);
  }

  /// Os ids de tudo o que está ativo no livro: gastos e entradas.
  static Set<String> _activeIds(LedgerBook book) => {
    for (final entry in book.entries) entry.id,
    for (final receipt in book.receipts) receipt.id,
  };

  /// Desfaz o que [outcome] gravou, gastos e entradas (RN-1119, RN-1120).
  /// Devolve quantos de fato saíram: o que outro celular já desfez não
  /// conta.
  Future<int> undo(StatementBatchOutcome outcome) async {
    final ledger = ref.read(ledgerProvider.notifier);
    var undone = 0;
    for (final id in outcome.entries) {
      final book = await ref.read(ledgerProvider.future);
      if (book.entryOf(id) == null) continue;
      await ledger.cancel(id, reason: 'Desfeito na conversa do extrato');
      undone++;
    }
    final incomes = ref.read(incomeServiceProvider);
    for (final id in outcome.incomes) {
      if (await incomes.cancelIncome(id)) undone++;
    }
    return undone;
  }

  /// A chave de cada linha pelo conteúdo (RN-1117): o texto lido, e não a
  /// descrição da IA.
  static List<String> _keys(List<ResolvedLine> lines) => StatementLineKey.of([
    for (final line in lines)
      (
        on: line.line.occurredOn,
        amount: line.line.amount,
        merchantKey: line.contentKey,
      ),
  ]);

  Future<Failure?> _one(ResolvedLine line, String id, String? cardId) async {
    final book = await ref.read(ledgerProvider.future);
    return line.isIncome
        ? await _receive(id, line, book)
        : await _spend(id, line, book, cardId);
  }

  Future<Failure?> _spend(
    String id,
    ResolvedLine line,
    LedgerBook book,
    String? cardId,
  ) async {
    final result = await ref
        .read(ledgerProvider.notifier)
        .record(
          EntryDraft(
            captureId: id,
            amountCents: line.line.amount.cents,
            description: line.line.description,
            occurredOn: line.line.occurredOn,
            category: book.categoriesById[line.line.categoryId],
            method: _method(line.line, book, cardId),
          ),
        );
    return result.failureOrNull;
  }

  /// Por onde saiu, sem nunca adivinhar pela última forma usada — que podia
  /// ser o vale (RN-111). Cartão: o escolhido, ou o único. Sem cartão
  /// cadastrado, a compra sai da conta.
  static PaymentMethod? _method(
    StatementLine line,
    LedgerBook book,
    String? cardId,
  ) {
    PaymentMethod? byId(String? id) =>
        book.methods.where((method) => method.id == id).firstOrNull;
    PaymentMethod? byKind(PaymentMethodKind kind) =>
        book.methods.where((method) => method.kind == kind).firstOrNull;
    final account =
        byKind(PaymentMethodKind.debit) ?? byKind(PaymentMethodKind.pix);
    if (line.paymentKind == PaymentMethodKind.creditCard) {
      final single = book.cards.length == 1 ? book.cards.single.id : null;
      return byId(cardId ?? single) ?? account;
    }
    return StatementImport.methodFor(line, book) ?? account;
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

/// O caso de uso de gravar o extrato conferido.
final statementBatchProvider = Provider<StatementBatch>(StatementBatch.new);

/// O que o lote vai juntando, linha a linha.
final class _Batch {
  final entries = <String>[];
  final incomes = <String>[];
  final refused = <int, Failure>{};
  int already = 0;

  void add(int index, ResolvedLine line, String id, Failure? failure) {
    if (failure != null) {
      refused[index] = failure;
      return;
    }
    (line.isIncome ? incomes : entries).add(id);
  }

  StatementBatchOutcome outcome(ErrorCode? stopped) => (
    entries: entries,
    incomes: incomes,
    refused: refused,
    alreadyThere: already,
    stopped: stopped,
  );
}
