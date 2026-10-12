import 'package:cajui/src/features/statements/presentation/statement_step.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// A fala da Juju que pede resposta no passo atual da conversa do extrato:
/// o cartão, as parcelas, o bloco, a dúvida, o que já estava e o convite a
/// lançar (RN-1111 a RN-1115). As palavras vêm do domínio.
abstract final class StatementPrompts {
  /// A fala do passo em que [talk] está.
  static Widget current(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
    Map<String, Category> categories,
  ) => switch (StatementStep.of(talk)) {
    CardStep(:final cards) => _juju(
      StatementWords.whichCard,
      options: [for (final card in cards) card.name],
      onOption: (name) =>
          model.chooseCard(cards.firstWhere((card) => card.name == name)),
    ),
    InstallmentStep() => _installments(talk, model),
    BlockStep(:final block) => _block(talk, model, block, categories),
    QuestionStep(:final question) => _question(
      talk,
      model,
      question,
      categories,
    ),
    AlreadyStep() => _already(talk, model),
    ReadyStep() => _juju(StatementWords.ready(talk.digest.ready.length)),
  };

  static Widget _juju(
    String text, {
    List<CajuiPromptRow> rows = const [],
    List<CajuiPromptAction> actions = const [],
    List<String> options = const [],
    ValueChanged<String>? onOption,
  }) => CajuiChatPrompt(
    text,
    speaker: AssistantIdentity.name,
    rows: rows,
    actions: actions,
    options: options,
    onOption: onOption,
  );

  /// As parcelas de outros meses, de uma vez (RN-1111).
  static Widget _installments(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
  ) {
    const key = 'parcelas';
    final open = talk.expanded.contains(key);
    return _juju(
      StatementWords.installments(talk.digest),
      rows: open ? _rows(talk, talk.digest.installments) : const [],
      actions: [
        (
          label: 'Lançar',
          onPressed: () => model.installments(launch: true),
          primary: true,
        ),
        _lines(model, key, open: open),
        (
          label: 'Não lançar',
          onPressed: () => model.installments(launch: false),
          primary: false,
        ),
      ],
    );
  }

  /// "Mercado — 12 compras… Confere?", com as linhas quando abertas.
  static Widget _block(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
    StatementBlock block,
    Map<String, Category> categories,
  ) {
    final key = block.categoryId;
    final said = StatementWords.block(
      block,
      categories[key]?.name ?? 'Outros',
      talk.lines,
    );
    final open = talk.expanded.contains(key);
    return _juju(
      said,
      rows: open ? _rows(talk, block.lines) : const [],
      actions: _blockActions(model, block, said, open: open),
    );
  }

  /// Os botões do bloco: Confere, Ver as linhas e Corrigir (RN-1113).
  static List<CajuiPromptAction> _blockActions(
    StatementTalkViewModel model,
    StatementBlock block,
    String said, {
    required bool open,
  }) => [
    (
      label: 'Confere',
      onPressed: () => model.confirm(block, said),
      primary: true,
    ),
    _lines(model, block.categoryId, open: open),
    (
      label: 'Corrigir',
      onPressed: () => model.correct(block, said),
      primary: false,
    ),
  ];

  /// O que já estava no Cajui: confere, ou inclui mesmo assim (RN-1112).
  static Widget _already(StatementTalkOpen talk, StatementTalkViewModel model) {
    const key = '';
    final open = talk.expanded.contains(key);
    final there = talk.digest.alreadyThere.toList()..sort();
    return _juju(
      StatementWords.already(there.length),
      rows: open ? _rows(talk, there) : const [],
      actions: [
        (
          label: 'Confere',
          onPressed: () => model.already(include: false),
          primary: true,
        ),
        _lines(model, key, open: open),
        (
          label: 'Incluir todas',
          onPressed: () => model.already(include: true),
          primary: false,
        ),
      ],
    );
  }

  static CajuiPromptAction _lines(
    StatementTalkViewModel model,
    String key, {
    required bool open,
  }) => (
    label: open ? 'Esconder as linhas' : 'Ver as linhas',
    onPressed: () => model.toggleLines(key),
    primary: false,
  );

  /// "05/10 · Assaí · R$ 412,30".
  static List<CajuiPromptRow> _rows(
    StatementTalkOpen talk,
    Iterable<int> lines,
  ) => [
    for (final i in lines)
      (
        label: StatementWords.row(talk.lines[i]),
        value: StatementWords.amount(talk.lines[i]),
      ),
  ];

  static Widget _question(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
    StatementQuestion question,
    Map<String, Category> categories,
  ) {
    final index = question.line;
    final said = StatementWords.question(question, talk.lines[index]);
    return switch (question) {
      KindQuestion(:final options) => _juju(
        said,
        options: [
          for (final option in options) StatementWords.treatment(option),
        ],
        onOption: (label) => model.answerKind(
          index,
          options.firstWhere((o) => StatementWords.treatment(o) == label),
          said,
        ),
      ),
      CategoryQuestion(:final candidates) => _category(talk, model, (
        index: index,
        said: said,
        candidates: candidates,
      ), categories),
    };
  }

  /// "Qual é a categoria?": as prováveis, "Outra" e "Não lançar"; depois de
  /// "Outra", todas.
  static Widget _category(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
    ({int index, String said, List<String> candidates}) asked,
    Map<String, Category> categories,
  ) {
    final all = talk.showingAll == asked.index;
    final offered = all
        ? categories.values.toList()
        : [for (final id in asked.candidates) ?categories[id]];
    return _juju(
      asked.said,
      options: [
        for (final category in offered) category.name,
        if (!all) _other,
        _skip,
      ],
      onOption: (label) => switch (label) {
        _other => model.showAll(asked.index),
        _skip => model.skip(asked.index, asked.said),
        _ => model.answerCategory(
          asked.index,
          offered.firstWhere((category) => category.name == label),
          asked.said,
        ),
      },
    );
  }

  static const _other = 'Outra';
  static const _skip = 'Não lançar';
}
