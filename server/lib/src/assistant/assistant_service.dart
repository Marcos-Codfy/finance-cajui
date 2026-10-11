import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/assistant/assistant_action.dart';
import 'package:server/src/assistant/assistant_answer.dart';
import 'package:server/src/assistant/assistant_context.dart';
import 'package:server/src/assistant/assistant_prompt.dart';
import 'package:server/src/assistant/assistant_tools.dart';
import 'package:server/src/assistant/conversation_window.dart';

/// O que saiu de uma pergunta: a resposta, ou o erro do catálogo.
typedef AssistantOutcome = ({
  AssistantAnswer? answer,
  ErrorCode? error,
  int? retryAfterSeconds,
});

/// Atende uma pergunta ao assistente (ADR-021).
///
/// A conversa é um laço: o modelo responde em texto, ou pede ferramentas;
/// cada pedido é atendido e devolvido a ele, até [maxToolRounds] vezes;
/// na última rodada ele não recebe ferramentas, e tem de responder com o
/// que já tem. O que ele fez no livro no caminho vai junto com a resposta.
final class AssistantService {
  /// Cria o serviço sobre o cliente de IA [client].
  new({
    required this.client,
    required this.budget,
    required this.breaker,
    ConversationWindow? window,
    this.timeout = const Duration(seconds: 25),
  }) : window = window ?? ConversationWindow();

  /// O cliente da IA.
  final ChatClient client;

  /// O orçamento de tokens, o mesmo da classificação (RN-960).
  final TokenBudget budget;

  /// O disjuntor da IA.
  final CircuitBreaker breaker;

  /// A janela da conversa de cada sessão.
  final ConversationWindow window;

  /// Quanto esperar por cada chamada à IA.
  final Duration timeout;

  /// Quantas rodadas de ferramenta uma pergunta pode disparar. Lançar, ver
  /// e cancelar cabem em três; a quarta existe para o modelo corrigir um
  /// argumento recusado.
  static const maxToolRounds = 4;

  /// Responde [message] da sessão [sessionId], com o [context] do mês, o
  /// [catalog] de categorias e cartões, e as [tools] que mexem no livro.
  Future<AssistantOutcome> ask({
    required String sessionId,
    required String message,
    required AssistantContext context,
    required Map<String, Object?> catalog,
    required AssistantTools tools,
  }) async {
    // O limite é conferido antes de qualquer chamada sair (RN-962).
    if (!budget.hasRoomIn(context.month)) return _failed(ErrorCode.ai03);
    if (!breaker.allowsCall) return _failed(ErrorCode.ai01);
    // A pergunta é mascarada antes de ser guardada ou enviada (RN-952).
    final question = PiiRedactor.redact(ReceiptText.clean(message));
    final messages = AssistantPrompt.messages(
      context: context,
      catalog: catalog,
      window: window.of(sessionId),
      message: question,
    );
    try {
      final answer = await _converse(messages, context, tools);
      window.add(sessionId, question, answer.text);
      return (answer: answer, error: null, retryAfterSeconds: null);
    } on ChatUnavailable catch (unavailable) {
      return _down(unavailable.retryAfterSeconds);
    } on TimeoutException {
      return _down(null);
    }
  }

  /// A IA não respondeu. O provedor pedindo uma pausa é outro erro, com a
  /// contagem (E-AI-02); o resto é "fora do ar" (E-AI-01).
  AssistantOutcome _down(int? retryAfterSeconds) {
    breaker.recordFailure();
    return _failed(
      retryAfterSeconds == null ? ErrorCode.ai01 : ErrorCode.ai02,
      retryAfterSeconds,
    );
  }

  static AssistantOutcome _failed(ErrorCode code, [int? retryAfterSeconds]) =>
      (answer: null, error: code, retryAfterSeconds: retryAfterSeconds);

  /// O laço da conversa. [messages] cresce com cada pedido de ferramenta e
  /// cada resultado, e é o que vai inteiro na chamada seguinte.
  Future<AssistantAnswer> _converse(
    List<ChatMessage> messages,
    AssistantContext context,
    AssistantTools tools,
  ) async {
    final actions = <AssistantAction>[];
    for (var round = 0; round <= maxToolRounds; round++) {
      final offered = round < maxToolRounds
          ? tools.offered
          : const <ChatTool>[];
      final reply = await _call(messages, offered, context);
      if (!reply.wantsTools) {
        return AssistantAnswer.fromText(reply.content, actions: actions) ??
            AssistantAnswer.fallback(actions: actions);
      }
      messages.add(
        ChatMessage.assistant(reply.content, toolCalls: reply.toolCalls),
      );
      for (final call in reply.toolCalls) {
        final outcome = await tools.run(call);
        if (outcome.action case final action?) actions.add(action);
        messages.add(ChatMessage.tool(outcome.json, toolCallId: call.id));
      }
    }
    return AssistantAnswer.fallback(actions: actions);
  }

  Future<ChatReply> _call(
    List<ChatMessage> messages,
    List<ChatTool> tools,
    AssistantContext context,
  ) async {
    final reply = await client
        .converse(messages: messages, tools: tools, maxTokens: 600)
        .timeout(timeout);
    breaker.recordSuccess();
    await budget.record(context.month, reply);
    return reply;
  }
}
