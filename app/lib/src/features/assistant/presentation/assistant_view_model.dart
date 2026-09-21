import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da conversa com o assistente (ADR-002).
///
/// A conversa da tela vive só aqui, na memória: fechar o app a esquece. É o
/// modo mais conservador da RN-957 — nada de conversa fica guardado no
/// aparelho.
class AssistantViewModel extends Notifier<AssistantState> {
  @override
  AssistantState build() => ref.watch(assistantGatewayProvider).isPaired
      ? const AssistantTalking()
      : const AssistantUnpaired();

  /// Pergunta [message]. Enquanto a resposta não chega, a tela espera: uma
  /// segunda pergunta só depois da primeira resposta.
  Future<void> ask(String message) async {
    final current = state;
    final question = message.trim();
    if (current is! AssistantTalking || current.isWaiting) return;
    if (question.isEmpty) return;
    state = current.asking(question);
    final reply = await ref.read(assistantGatewayProvider).ask(question);
    state = reply is AssistantNotPaired
        ? const AssistantUnpaired()
        : current.answered(question, reply);
  }

  /// Pergunta de novo a última pergunta, depois de uma falha.
  Future<void> retry() async {
    final current = state;
    if (current is! AssistantTalking || current.exchanges.isEmpty) return;
    final (question, _) = current.exchanges.last;
    state = current.withoutLast();
    await ask(question);
  }
}

/// A conversa em curso.
final assistantProvider = NotifierProvider<AssistantViewModel, AssistantState>(
  AssistantViewModel.new,
);
