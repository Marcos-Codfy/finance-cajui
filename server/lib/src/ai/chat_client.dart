import 'package:server/src/ai/chat_reply.dart';

/// A porta para um modelo de linguagem. A DeepSeek é um adaptador; nos
/// testes, um cliente de mentira devolve as respostas hostis da suíte de
/// comprovantes maliciosos (ADR-010).
abstract interface class ChatClient {
  /// Envia as instruções [system] e o conteúdo [user], e devolve a resposta.
  /// Lança `ChatUnavailable` quando o serviço falha, demora ou limita.
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  });
}
