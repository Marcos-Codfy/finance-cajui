import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/chat_tool.dart';

/// A porta para um modelo de linguagem. A DeepSeek é um adaptador; nos
/// testes, um cliente de mentira devolve o que o roteiro mandar (ADR-010).
///
/// Duas formas de perguntar. [complete] é a pergunta de uma vez só, em JSON
/// fechado — a classificação de comprovante. [converse] é a conversa com
/// histórico e ferramentas — o assistente. Quem só sabe a primeira ganha a
/// segunda de graça, sem ferramentas: é o bastante para os dublês antigos.
abstract class ChatClient {
  /// Cria a porta.
  const new();

  /// Envia as instruções [system] e o conteúdo [user], e devolve a resposta.
  /// Lança `ChatUnavailable` quando o serviço falha, demora ou limita.
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  });

  /// Continua a conversa [messages], oferecendo [tools] ao modelo. A
  /// resposta traz texto, ou os pedidos de ferramenta a atender antes de
  /// chamar de novo.
  Future<ChatReply> converse({
    required List<ChatMessage> messages,
    required int maxTokens,
    List<ChatTool> tools = const [],
  }) {
    final system = [
      for (final message in messages)
        if (message.role == ChatRole.system) message.content,
    ].join('\n');
    final talk = [
      for (final message in messages)
        if (message.role != ChatRole.system)
          '${message.role.name}: ${message.content}',
    ].join('\n');
    return complete(system: system, user: talk, maxTokens: maxTokens);
  }
}
