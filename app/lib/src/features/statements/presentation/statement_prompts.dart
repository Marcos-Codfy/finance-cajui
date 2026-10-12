import 'package:cajui/src/features/statements/presentation/statement_step.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As falas da Juju que pedem resposta na conversa do extrato: o bloco a
/// conferir, a dúvida com as opções, e o fim, com o desfazer (RN-1113,
/// RN-1114, RN-1119). As palavras vêm do domínio (`StatementWords`).
abstract final class StatementPrompts {
  /// A fala do passo em que [talk] está.
  static Widget current(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
    Map<String, Category> categories,
  ) => switch (StatementStep.of(talk)) {
    BlockStep(:final block) => _block(talk, model, block, categories),
    QuestionStep(:final question) => _question(
      talk,
      model,
      question,
      categories,
    ),
    ReadyStep() => CajuiChatPrompt(
      StatementWords.ready(talk.digest.ready.length),
      speaker: AssistantIdentity.name,
    ),
  };

  /// "Mercado — 12 compras… Confere?", com as linhas quando abertas.
  static Widget _block(
    StatementTalkOpen talk,
    StatementTalkViewModel model,
    StatementBlock block,
    Map<String, Category> categories,
  ) {
    final category = block.categoryId;
    final said = StatementWords.block(
      block,
      categories[category]?.name ?? 'Outros',
      talk.lines,
    );
    final open = talk.expanded.contains(category);
    return CajuiChatPrompt(
      said,
      speaker: AssistantIdentity.name,
      rows: open ? _rows(talk, block) : const [],
      actions: _blockActions(model, block, said, open: open),
    );
  }

  /// Os botões do bloco: Confere, Ver as linhas e Corrigir (RN-1113).
  static List<CajuiPromptAction> _blockActions(
    StatementTalkViewModel model,
    StatementBlock block,
    String said, {
    required bool open,
  }) {
    final category = block.categoryId;
    return [
      (
        label: 'Confere',
        onPressed: () => model.confirm(category, said),
        primary: true,
      ),
      (
        label: open ? 'Esconder as linhas' : 'Ver as linhas',
        onPressed: () => model.toggleLines(category),
        primary: false,
      ),
      (
        label: 'Corrigir',
        onPressed: () => model.correct(block, said),
        primary: false,
      ),
    ];
  }

  /// "05/10 · Assaí · R$ 412,30", do maior para o menor.
  static List<CajuiPromptRow> _rows(
    StatementTalkOpen talk,
    StatementBlock block,
  ) => [
    for (final i in block.lines)
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
      KindQuestion(:final options) => CajuiChatPrompt(
        said,
        speaker: AssistantIdentity.name,
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
    return CajuiChatPrompt(
      asked.said,
      speaker: AssistantIdentity.name,
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

  /// O fim: as recusas, quando há, o desfazer e o "Pronto".
  static Widget done(StatementTalkDone done, StatementTalkViewModel model) {
    final recorded = done.outcome.entries.length + done.outcome.incomes.length;
    return CajuiChatPrompt(
      done.refusals.isEmpty ? 'Fica assim?' : done.refusals.join('\n'),
      speaker: AssistantIdentity.name,
      actions: [
        (label: 'Pronto', onPressed: model.close, primary: true),
        if (!done.undone && recorded > 0)
          (label: 'Desfazer tudo', onPressed: model.undo, primary: false),
      ],
    );
  }
}
