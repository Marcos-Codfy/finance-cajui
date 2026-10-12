import 'dart:async';

import 'package:cajui/src/features/ledger/application/answer_memory.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/statements/application/statement_batch.dart';
import 'package:cajui/src/features/statements/application/statement_resolution.dart';
import 'package:cajui/src/features/statements/presentation/statement_endings.dart';
import 'package:cajui/src/features/statements/presentation/statement_opening.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_changes.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversa do extrato com a Juju (RN-1100 a RN-1120): lê, resume,
/// confere, pergunta, lança em lote e desfaz.
///
/// Cada resposta vai para a memória (RN-1116) e a conversa é resolvida de
/// novo com ela. Nada é gravado antes de "Pode lançar" (RN-1115), e o que
/// "Pode lançar" grava é resolvido de novo contra o livro daquele instante:
/// o que entrou por outro caminho durante a conversa não entra em dobro.
class StatementTalkViewModel extends Notifier<StatementTalkState> {
  /// Os extratos que chegaram com outra conversa aberta: esperam a vez, em
  /// vez de cair na lista antiga ou interromper a que está no meio.
  final List<Capture> _waiting = [];

  /// A leitura em curso; "Parar" a troca, e o resultado da velha é
  /// descartado quando chega.
  int _reading = 0;

  /// Uma ação gravando: o segundo toque não roda de novo.
  bool _busy = false;

  @override
  StatementTalkState build() => const StatementTalkIdle();

  /// Lê o extrato de [capture], página a página (RN-1101, RN-1102).
  Future<void> start(Capture capture) async {
    final current = state;
    if (current is StatementTalkReading ||
        current is StatementTalkOpen ||
        current is StatementTalkSaving) {
      _waiting.add(capture);
      return;
    }
    final reading = ++_reading;
    state = const StatementTalkReading();
    final opened = await StatementOpening(ref).open(
      capture,
      onPage: (page, of) {
        if (reading != _reading) return;
        state = StatementTalkReading(page: page, of: of);
      },
    );
    if (reading == _reading) state = opened;
  }

  /// "Parar" a leitura: a captura fica em "Para conferir".
  void stop() {
    _reading++;
    _next();
  }

  /// "Tentar de novo", depois de uma falha.
  Future<void> retry() async {
    final failed = state;
    if (failed is! StatementTalkFailed) return;
    final capture = failed.capture;
    state = const StatementTalkIdle();
    if (capture != null) await start(capture);
  }

  /// "Confere".
  void confirm(StatementBlock block, String said) =>
      _change((talk) => StatementTalkChanges.confirm(talk, block, said));

  /// "Ver as linhas".
  void toggleLines(String key) =>
      _change((talk) => StatementTalkChanges.toggle(talk, key));

  /// "Outra".
  void showAll(int index) =>
      _change((talk) => StatementTalkChanges.showAll(talk, index));

  /// "Corrigir" (RN-1113).
  Future<void> correct(StatementBlock block, String said) =>
      _refresh((talk) => StatementTalkChanges.correct(talk, block, said));

  /// "Não lançar" numa linha em correção.
  Future<void> skip(int index, String said) =>
      _refresh((talk) => StatementTalkChanges.skip(talk, index, said));

  /// As parcelas: lançar ou não, todas de uma vez (RN-1111).
  Future<void> installments({required bool launch}) => _refresh(
    (talk) => StatementTalkChanges.installments(talk, launch: launch),
  );

  /// O cartão das compras no cartão (RN-1114).
  Future<void> chooseCard(StatementCard card) =>
      _refresh((talk) => StatementTalkChanges.card(talk, card));

  /// O que já estava no Cajui: confere, ou inclui mesmo assim.
  Future<void> already({required bool include}) =>
      _refresh((talk) => StatementTalkChanges.already(talk, include: include));

  /// A resposta de tipo da linha [index] (RN-1116).
  Future<void> answerKind(int index, LineTreatment treatment, String said) =>
      _answer(index, said, StatementWords.treatment(treatment), (
        treatment: treatment,
        categoryId: null,
      ));

  /// A categoria da linha [index] (RN-1116).
  Future<void> answerCategory(int index, Category category, String said) =>
      _answer(index, said, category.name, (
        treatment: null,
        categoryId: category.id,
      ));

  /// A resposta é lembrada quando a linha tem nome que sirva de chave; a
  /// de linha sem nome vale só nesta conversa.
  Future<void> _answer(
    int index,
    String said,
    String label,
    ({LineTreatment? treatment, String? categoryId}) answer,
  ) => _guarded(() async {
    final talk = state;
    if (talk is! StatementTalkOpen) return;
    final line = talk.lines[index];
    final given = LearnedAnswer(
      key: line.merchantKey,
      treatment: answer.treatment,
      categoryId: answer.categoryId,
      aboutPerson: line.person != null,
      definedAt: ref.read(clockProvider).now(),
    );
    if (line.rememberable) await _remember(given);
    await _refresh(
      (talk) => StatementTalkChanges.answered(
        talk,
        index,
        said,
        label,
        local: line.rememberable ? null : given,
      ),
    );
  });

  Future<void> _remember(LearnedAnswer answer) => ref
      .read(answerMemoryProvider)
      .remember(
        key: answer.key,
        treatment: answer.treatment,
        categoryId: answer.categoryId,
        aboutPerson: answer.aboutPerson,
      );

  /// "Pode lançar": resolve de novo contra o livro de agora e grava o lote
  /// (RN-1115, RN-1117, RN-1118).
  Future<void> launch() => _guarded(() async {
    final current = state;
    if (current is! StatementTalkOpen) return;
    final talk = await _resolved(current, current.choices);
    state = StatementTalkSaving(talk.history);
    final outcome = await ref
        .read(statementBatchProvider)
        .record(
          talk.lines,
          talk.digest.ready,
          launch: ref.read(newIdProvider)(),
          cardId: talk.cardId,
        );
    state = StatementTalkDone(
      talk: talk,
      history: [
        ...talk.history,
        (juju: StatementEndings.doneWords(outcome), answer: null),
      ],
      outcome: outcome,
      refusals: StatementEndings.refusals(talk, outcome),
    );
  });

  /// No "Pronto", a captura fecha — a não ser que reste dúvida sem
  /// resposta, ou que o lote tenha parado no meio: aí ela fica em "Para
  /// conferir". Fecha só aqui, e não ao lançar, para o "Desfazer tudo"
  /// ainda achar a captura guardada.
  Future<void> _settle(StatementTalkDone done) async {
    final capture = done.talk.capture;
    final pending =
        done.talk.digest.questions.isNotEmpty || done.outcome.stopped != null;
    if (capture != null && !pending) {
      await ref.read(captureServiceProvider).close(capture);
    }
  }

  /// "Desfazer tudo": o lote sai, a captura volta a "Para conferir" e a
  /// conversa volta, para lançar de novo se quiser (RN-1119).
  Future<void> undo() => _guarded(() async {
    final done = state;
    if (done is! StatementTalkDone) return;
    final count = await ref.read(statementBatchProvider).undo(done.outcome);
    final talk = done.talk.copyWith(
      history: [
        ...done.history,
        (juju: StatementWords.undone(count), answer: 'Desfazer tudo'),
      ],
    );
    state = await _resolved(talk, talk.choices);
  });

  /// "Descartar": o extrato sai de "Para conferir" sem gravar nada.
  Future<void> discard() => _guarded(() async {
    final capture = switch (state) {
      StatementTalkOpen(:final capture) => capture,
      StatementTalkFailed(:final capture) => capture,
      _ => null,
    };
    if (capture != null) {
      await ref.read(captureServiceProvider).discard(capture);
    }
    _next();
  });

  /// "Conferir depois" ou "Pronto": a conversa fecha, e o próximo extrato
  /// da fila abre.
  Future<void> close() => _guarded(() async {
    final done = state;
    if (done is StatementTalkDone) await _settle(done);
    _next();
  });

  void _next() {
    state = const StatementTalkIdle();
    if (_waiting.isNotEmpty) unawaited(start(_waiting.removeAt(0)));
  }

  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

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
    state = await _resolved(changed, changed.choices);
  }

  Future<StatementTalkOpen> _resolved(
    StatementTalkOpen talk,
    StatementChoices choices,
  ) async {
    final book = await ref.read(ledgerProvider.future);
    final resolved = StatementResolution.of(
      talk.reading,
      book,
      choices: choices,
    );
    return talk.resolvedAs(
      resolved.lines,
      StatementDigest.of(
        resolved.lines,
        alreadyThere: resolved.alreadyThere,
        skipped: talk.skipped,
      ),
    );
  }
}

/// A conversa do extrato em curso.
final statementTalkProvider =
    NotifierProvider<StatementTalkViewModel, StatementTalkState>(
      StatementTalkViewModel.new,
    );
