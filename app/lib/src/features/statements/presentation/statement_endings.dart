import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/statements/application/statement_batch.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As falas de começo e de fim da conversa do extrato: lendo, lançado e a
/// falha — cada uma com uma saída, para a conversa nunca ficar presa.
abstract final class StatementEndings {
  /// "Lendo a página 3 de 7…", com "Parar".
  static Widget reading(int page, int of, StatementTalkViewModel model) =>
      CajuiChatPrompt(
        of == 0 ? StatementWords.opening : StatementWords.reading(page, of),
        speaker: AssistantIdentity.name,
        actions: [(label: 'Parar', onPressed: model.stop, primary: false)],
      );

  /// O fim: as recusas, quando há, o "Pronto" e o desfazer (RN-1118,
  /// RN-1119).
  static Widget done(StatementTalkDone done, StatementTalkViewModel model) {
    final recorded = done.outcome.entries.length + done.outcome.incomes.length;
    return CajuiChatPrompt(
      done.refusals.isEmpty ? 'Fica assim?' : done.refusals.join('\n'),
      speaker: AssistantIdentity.name,
      actions: [
        (label: 'Pronto', onPressed: model.close, primary: true),
        if (recorded > 0)
          (label: 'Desfazer tudo', onPressed: model.undo, primary: false),
      ],
    );
  }

  /// A leitura não deu: o texto do catálogo, já com os valores no lugar
  /// (RN-1102), e as saídas.
  static Widget failed(
    StatementTalkFailed failed,
    StatementTalkViewModel model, {
    required BudgetMonth month,
  }) => CajuiChatPrompt(
    textOf(failed.code, month: month),
    speaker: AssistantIdentity.name,
    actions: [
      if (failed.code != null)
        (label: 'Tentar de novo', onPressed: model.retry, primary: true),
      (label: 'Descartar', onPressed: model.discard, primary: false),
      (label: 'Fechar', onPressed: model.close, primary: false),
    ],
  );

  /// O texto da falha [code]: o do catálogo, no contexto da captura e com
  /// as chaves preenchidas; sem código, a leitura não achou movimentação.
  static String textOf(ErrorCode? code, {required BudgetMonth month}) {
    if (code == null) {
      return StatementWords.summary(StatementDigest.of(const []));
    }
    return ErrorTexts.of(code).inContext('Na captura').fill({
      'recurso': 'Ler o extrato',
      'ação': 'ler o extrato',
      'mês': CalendarWords.month(month),
    }).message;
  }

  /// O que a Juju diz ao lançar (RN-1118): os que entraram, os que já
  /// estavam, os recusados e o erro que parou o lote, quando parou.
  static String doneWords(StatementBatchOutcome done) {
    final words = StatementWords.done(
      recorded: done.entries.length + done.incomes.length,
      already: done.alreadyThere,
      refused: done.refused.length,
    );
    final stopped = done.stopped;
    return stopped == null ? words : '$words ${ErrorTexts.of(stopped).message}';
  }

  /// Cada linha recusada, com o texto do catálogo.
  static List<String> refusals(
    StatementTalkOpen talk,
    StatementBatchOutcome done,
  ) => [
    for (final MapEntry(key: index, value: failure) in done.refused.entries)
      _refusal(talk.lines[index], failure),
  ];

  static String _refusal(ResolvedLine line, Failure failure) =>
      '"${line.line.description}" não entrou: '
      '${FailurePresenter.present(failure).text.message}';
}
