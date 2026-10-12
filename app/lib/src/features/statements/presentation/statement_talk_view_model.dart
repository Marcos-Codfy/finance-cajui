import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/answer_memory.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/statements/application/statement_batch.dart';
import 'package:cajui/src/features/statements/application/statement_page.dart';
import 'package:cajui/src/features/statements/application/statement_reader.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:cajui/src/features/statements/application/statement_resolution.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversa do extrato com a Juju (RN-1100 a RN-1120): lê, resume,
/// confere por blocos, pergunta as dúvidas, lança em lote e desfaz.
///
/// Cada resposta vai para a memória (RN-1116) e a conversa é resolvida de
/// novo com ela: uma resposta só resolve todas as linhas do mesmo lugar.
/// Nada é gravado no livro antes de "Pode lançar" (RN-1115).
class StatementTalkViewModel extends Notifier<StatementTalkState> {
  @override
  StatementTalkState build() => const StatementTalkIdle();

  /// Lê o extrato de [capture], página a página (RN-1101, RN-1102).
  Future<void> start(Capture capture) async {
    final path = capture.source.filePath;
    if (path == null) return;
    state = const StatementTalkReading();
    final read = await ref
        .read(receiptReaderProvider)
        .read(
          SharedFile(
            id: capture.source.id,
            path: path,
            isPdf: capture.source.isPdf,
          ),
        );
    if (read is! ReadText) {
      state = StatementTalkFailed((read as ReadFailed).code);
      return;
    }
    final reading = await _read(read);
    if (reading.lines.isEmpty) {
      state = StatementTalkFailed(reading.failure ?? ErrorCode.capt01);
      return;
    }
    await _open(capture, reading);
  }

  Future<StatementReading> _read(ReadText read) async {
    final book = await ref.read(ledgerProvider.future);
    return await ref
        .read(statementReaderProvider)
        .read(
          StatementPage.ofRead(read),
          knowsCategory: book.categoriesById.containsKey,
          pageCount: read.pageCount,
          examples: book.learnedAnswers.examples,
          household: book.householdNames,
          onPage: (page, of) =>
              state = StatementTalkReading(page: page, of: of),
        );
  }

  Future<void> _open(Capture capture, StatementReading reading) async {
    final book = await ref.read(ledgerProvider.future);
    final resolved = StatementResolution.of(reading, book);
    final digest = StatementDigest.of(
      resolved.lines,
      alreadyThere: resolved.alreadyThere,
    );
    final pages = StatementWords.pages(
      read: reading.pagesRead,
      total: reading.pageCount,
      failed: reading.failedPages,
      partial: reading.partialPages,
    );
    state = StatementTalkOpen(
      capture: capture,
      reading: reading,
      lines: resolved.lines,
      digest: digest,
      categoryOrder: [for (final category in book.categories) category.id],
      history: [
        (
          juju: [StatementWords.summary(digest), ?pages].join(' '),
          answer: null,
        ),
      ],
    );
  }

  /// "Confere": o bloco [categoryId] entra como está.
  void confirm(String categoryId, String said) => _change(
    (talk) => talk.copyWith(
      confirmed: {...talk.confirmed, categoryId},
      history: [...talk.history, (juju: said, answer: 'Confere')],
    ),
  );

  /// "Ver as linhas": mostra ou esconde as linhas do bloco.
  void toggleLines(String categoryId) => _change(
    (talk) => talk.copyWith(
      expanded: talk.expanded.contains(categoryId)
          ? ({...talk.expanded}..remove(categoryId))
          : {...talk.expanded, categoryId},
    ),
  );

  /// "Corrigir": cada linha do bloco vira pergunta de categoria (RN-1113).
  Future<void> correct(StatementBlock block, String said) => _refresh(
    (talk) => talk.copyWith(
      reviewing: {...talk.reviewing, ...block.lines},
      history: [...talk.history, (juju: said, answer: 'Corrigir')],
    ),
  );

  /// A resposta de tipo da linha [index], lembrada (RN-1116).
  Future<void> answerKind(int index, LineTreatment treatment, String said) =>
      _answer(index, said, StatementWords.treatment(treatment), (line) {
        return ref
            .read(answerMemoryProvider)
            .remember(
              key: line.merchantKey,
              treatment: treatment,
              aboutPerson: line.person != null,
            );
      });

  /// A categoria da linha [index], lembrada (RN-1116).
  Future<void> answerCategory(int index, Category category, String said) =>
      _answer(index, said, category.name, (line) {
        return ref
            .read(answerMemoryProvider)
            .remember(
              key: line.merchantKey,
              categoryId: category.id,
              aboutPerson: line.person != null,
            );
      });

  /// "Não lançar" na correção: a linha sai desta vez, sem lembrar.
  Future<void> skip(int index, String said) => _refresh(
    (talk) => talk.copyWith(
      skipped: {...talk.skipped, index},
      reviewing: {...talk.reviewing}..remove(index),
      showingAll: () => null,
      history: [...talk.history, (juju: said, answer: 'Não lançar')],
    ),
  );

  /// "Outra": a pergunta passa a mostrar todas as categorias.
  void showAll(int index) =>
      _change((talk) => talk.copyWith(showingAll: () => index));

  Future<void> _answer(
    int index,
    String said,
    String answer,
    Future<bool> Function(ResolvedLine line) remember,
  ) async {
    final talk = state;
    if (talk is! StatementTalkOpen) return;
    await remember(talk.lines[index]);
    await _refresh(
      (talk) => talk.copyWith(
        reviewing: {...talk.reviewing}..remove(index),
        showingAll: () => null,
        history: [...talk.history, (juju: said, answer: answer)],
      ),
    );
  }

  /// "Pode lançar": grava o lote e fecha a captura (RN-1115, RN-1118).
  Future<void> launch() async {
    final talk = state;
    if (talk is! StatementTalkOpen) return;
    state = StatementTalkSaving(talk.history);
    final outcome = await ref
        .read(statementBatchProvider)
        .record(talk.lines, talk.digest.ready);
    final capture = talk.capture;
    if (capture != null) await ref.read(captureServiceProvider).close(capture);
    final recorded = outcome.entries.length + outcome.incomes.length;
    state = StatementTalkDone(
      history: [
        ...talk.history,
        (juju: StatementWords.done(recorded), answer: null),
      ],
      outcome: outcome,
      refusals: _refusals(talk, outcome),
    );
  }

  /// "Desfazer": tudo o que o lote gravou sai (RN-1119).
  Future<void> undo() async {
    final done = state;
    if (done is! StatementTalkDone || done.undone) return;
    final count = await ref.read(statementBatchProvider).undo(done.outcome);
    state = StatementTalkDone(
      history: [
        ...done.history,
        (juju: StatementWords.undone(count), answer: 'Desfazer'),
      ],
      outcome: done.outcome,
      refusals: const [],
      undone: true,
    );
  }

  /// "Conferir depois" ou "Pronto": a conversa fecha. A captura continua em
  /// "Para conferir" até ser lançada.
  void close() => state = const StatementTalkIdle();

  List<String> _refusals(StatementTalkOpen talk, StatementBatchOutcome done) =>
      [
        for (final MapEntry(key: index, value: failure) in done.refused.entries)
          _refusal(talk.lines[index], failure),
      ];

  static String _refusal(ResolvedLine line, Failure failure) =>
      '"${line.line.description}" não entrou: '
      '${FailurePresenter.present(failure).text.message}';

  void _change(StatementTalkOpen Function(StatementTalkOpen talk) change) {
    final talk = state;
    if (talk is StatementTalkOpen) state = change(talk);
  }

  /// Aplica [change] e resolve as linhas de novo com o livro de agora: a
  /// memória pode ter mudado.
  Future<void> _refresh(
    StatementTalkOpen Function(StatementTalkOpen talk) change,
  ) async {
    final talk = state;
    if (talk is! StatementTalkOpen) return;
    final changed = change(talk);
    final book = await ref.read(ledgerProvider.future);
    final resolved = StatementResolution.of(
      changed.reading,
      book,
      reviewing: changed.reviewing,
    );
    state = changed.copyWith(
      lines: resolved.lines,
      digest: StatementDigest.of(
        resolved.lines,
        alreadyThere: resolved.alreadyThere,
        skipped: changed.skipped,
      ),
    );
  }
}

/// A conversa do extrato em curso.
final statementTalkProvider =
    NotifierProvider<StatementTalkViewModel, StatementTalkState>(
      StatementTalkViewModel.new,
    );
