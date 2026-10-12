import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/statements/presentation/statement_prompts.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversa do extrato dentro da conversa da Juju (RN-1100): o que já foi
/// dito, como falas comuns, e a fala que pede resposta agora.
class StatementThread extends ConsumerWidget {
  /// Cria a conversa do extrato.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statementTalkProvider);
    final model = ref.read(statementTalkProvider.notifier);
    final categories =
        ref.watch(ledgerProvider).value?.categoriesById ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _children(state, model, categories),
    );
  }

  static List<Widget> _children(
    StatementTalkState state,
    StatementTalkViewModel model,
    Map<String, Category> categories,
  ) => switch (state) {
    StatementTalkIdle() => const [],
    StatementTalkReading(:final page, :final of) => [
      _juju(
        of == 0 ? StatementWords.opening : StatementWords.reading(page, of),
      ),
    ],
    StatementTalkOpen() => [
      ..._history(state.history),
      StatementPrompts.current(state, model, categories),
    ],
    StatementTalkSaving(:final history) => [
      ..._history(history),
      _juju(StatementWords.saving),
    ],
    StatementTalkDone() => [
      ..._history(state.history),
      StatementPrompts.done(state, model),
    ],
    StatementTalkFailed(:final code) => [_failed(code, model)],
  };

  /// A leitura não deu: o texto do catálogo, e fechar.
  static Widget _failed(ErrorCode code, StatementTalkViewModel model) =>
      CajuiChatPrompt(
        ErrorTexts.of(code).message,
        speaker: AssistantIdentity.name,
        actions: [(label: 'Fechar', onPressed: model.close, primary: true)],
      );

  static Widget _juju(String text) =>
      CajuiChatBubble(text, speaker: AssistantIdentity.name);

  /// Cada fala passada, e a resposta da pessoa logo abaixo.
  static List<Widget> _history(List<StatementTurn> history) => [
    for (final turn in history) ...[
      _juju(turn.juju),
      if (turn.answer case final answer?)
        CajuiChatBubble(answer, fromUser: true),
    ],
  ];
}
