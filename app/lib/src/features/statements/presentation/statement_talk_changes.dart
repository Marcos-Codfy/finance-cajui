import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:domain/domain.dart';

/// As mudanças da conversa do extrato que não tocam o livro: o que a pessoa
/// conferiu, abriu, corrigiu ou escolheu (RN-1111 a RN-1114).
///
/// São puras. O ViewModel só as aplica e, quando a mudança pede, resolve as
/// linhas de novo; assim cada passo da conversa se testa sem montar tela.
abstract final class StatementTalkChanges {
  /// "Confere": as linhas do bloco ficam conferidas.
  static StatementTalkOpen confirm(
    StatementTalkOpen talk,
    StatementBlock block,
    String said,
  ) => talk.copyWith(
    confirmed: {...talk.confirmed, ...block.lines},
    history: _said(talk, said, 'Confere'),
  );

  /// "Ver as linhas": mostra ou esconde a lista do bloco [key].
  static StatementTalkOpen toggle(StatementTalkOpen talk, String key) =>
      talk.copyWith(
        expanded: talk.expanded.contains(key)
            ? ({...talk.expanded}..remove(key))
            : {...talk.expanded, key},
      );

  /// "Corrigir": cada linha do bloco vira pergunta de categoria (RN-1113).
  static StatementTalkOpen correct(
    StatementTalkOpen talk,
    StatementBlock block,
    String said,
  ) => talk.copyWith(
    reviewing: {...talk.reviewing, ...block.lines},
    confirmed: {...talk.confirmed}..removeAll(block.lines),
    history: _said(talk, said, 'Corrigir'),
  );

  /// A linha [index] foi respondida com [answer]. [local] é a resposta que
  /// vale só nesta conversa, quando a linha não pode ser lembrada.
  static StatementTalkOpen answered(
    StatementTalkOpen talk,
    int index,
    String said,
    String answer, {
    LearnedAnswer? local,
  }) => talk.copyWith(
    reviewing: {...talk.reviewing}..remove(index),
    confirmed: {...talk.confirmed, index},
    overrides: local == null
        ? talk.overrides
        : {...talk.overrides, index: local.merging(talk.overrides[index])},
    showingAll: () => null,
    history: _said(talk, said, answer),
  );

  /// "Não lançar" numa linha em correção: ela sai desta vez, sem lembrar.
  static StatementTalkOpen skip(
    StatementTalkOpen talk,
    int index,
    String said,
  ) => talk.copyWith(
    skipped: {...talk.skipped, index},
    reviewing: {...talk.reviewing}..remove(index),
    confirmed: {...talk.confirmed, index},
    showingAll: () => null,
    history: _said(talk, said, 'Não lançar'),
  );

  /// As parcelas de outros meses entram como gasto do mês, ou ficam de fora
  /// — todas de uma vez (RN-1111).
  static StatementTalkOpen installments(
    StatementTalkOpen talk, {
    required bool launch,
  }) => talk.copyWith(
    installments: launch,
    skipped: launch
        ? talk.skipped
        : {...talk.skipped, ...talk.digest.installments},
    history: _said(
      talk,
      StatementWords.installments(talk.digest),
      launch ? 'Lançar' : 'Não lançar',
    ),
  );

  /// O cartão das compras no cartão deste extrato (RN-1114).
  static StatementTalkOpen card(StatementTalkOpen talk, StatementCard card) =>
      talk.copyWith(
        cardId: card.id,
        history: _said(talk, StatementWords.whichCard, card.name),
      );

  /// O que já estava no Cajui: fica de fora, ou entra mesmo assim.
  static StatementTalkOpen already(
    StatementTalkOpen talk, {
    required bool include,
  }) => talk.seenAlready(
    include ? talk.digest.alreadyThere : const {},
    _said(
      talk,
      StatementWords.already(talk.digest.alreadyThere.length),
      include ? 'Incluir todas' : 'Confere',
    ),
  );

  /// "Outra": a pergunta passa a mostrar todas as categorias.
  static StatementTalkOpen showAll(StatementTalkOpen talk, int index) =>
      talk.copyWith(showingAll: () => index);

  static List<StatementTurn> _said(
    StatementTalkOpen talk,
    String juju,
    String answer,
  ) => [...talk.history, (juju: juju, answer: answer)];
}
