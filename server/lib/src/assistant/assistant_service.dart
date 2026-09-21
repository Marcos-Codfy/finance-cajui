import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/assistant/assistant_answer.dart';
import 'package:server/src/assistant/assistant_context.dart';
import 'package:server/src/assistant/assistant_prompt.dart';
import 'package:server/src/assistant/conversation_window.dart';

/// O que saiu de uma pergunta: a resposta, ou o erro do catálogo.
typedef AssistantOutcome = ({
  AssistantAnswer? answer,
  ErrorCode? error,
  int? retryAfterSeconds,
});

/// Atende uma pergunta ao assistente (RN-901 a RN-964).
///
/// Não tem porta de escrita para fato financeiro (RN-904): recebe o contexto
/// já montado e só fala com a IA. O único registro que uma conversa deixa é
/// o consumo de tokens.
final class AssistantService {
  /// Cria o serviço sobre o cliente de IA [client].
  new({
    required this.client,
    required this.budget,
    required this.breaker,
    ConversationWindow? window,
    this.timeout = const Duration(seconds: 20),
  }) : window = window ?? ConversationWindow();

  /// O cliente da IA.
  final ChatClient client;

  /// O orçamento de tokens, o mesmo da classificação (RN-960).
  final TokenBudget budget;

  /// O disjuntor da IA.
  final CircuitBreaker breaker;

  /// A janela da conversa de cada sessão.
  final ConversationWindow window;

  /// Quanto esperar pela IA.
  final Duration timeout;

  /// Uma resposta reprovada gera **uma** nova tentativa (RN-945).
  static const _attempts = 2;

  /// Responde [message] da sessão [sessionId], com o [context] do mês.
  Future<AssistantOutcome> ask({
    required String sessionId,
    required String message,
    required AssistantContext context,
  }) async {
    // O limite é conferido antes de qualquer chamada sair (RN-962).
    if (!budget.hasRoomIn(context.month)) {
      return _failed(ErrorCode.ai03);
    }
    if (!breaker.allowsCall) return _failed(ErrorCode.ai01);
    // A pergunta é mascarada antes de ser guardada ou enviada (RN-952).
    final question = PiiRedactor.redact(ReceiptText.clean(message));
    try {
      final answer =
          await _validAnswer(sessionId, question, context) ??
          AssistantAnswer.fallback(context);
      window.add(sessionId, question, answer.text);
      return (answer: answer, error: null, retryAfterSeconds: null);
    } on ChatUnavailable catch (unavailable) {
      breaker.recordFailure();
      // O provedor pediu uma pausa: é outro erro, com a contagem (E-AI-02).
      final wait = unavailable.retryAfterSeconds;
      return _failed(wait == null ? ErrorCode.ai01 : ErrorCode.ai02, wait);
    } on TimeoutException {
      breaker.recordFailure();
      return _failed(ErrorCode.ai01);
    }
  }

  static AssistantOutcome _failed(ErrorCode code, [int? retryAfterSeconds]) =>
      (answer: null, error: code, retryAfterSeconds: retryAfterSeconds);

  /// A primeira resposta que passa na validação, em até [_attempts] chamadas.
  Future<AssistantAnswer?> _validAnswer(
    String sessionId,
    String question,
    AssistantContext context,
  ) async {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final reply = await client
          .complete(
            system: AssistantPrompt.system,
            user: AssistantPrompt.user(
              context: context,
              window: window.of(sessionId),
              message: question,
            ),
            maxTokens: 400,
          )
          .timeout(timeout);
      breaker.recordSuccess();
      await budget.record(context.month, reply);
      final answer = AssistantAnswer.parse(
        reply.content,
        context: context,
        question: question,
      );
      if (answer != null) return answer;
    }
    return null;
  }
}
