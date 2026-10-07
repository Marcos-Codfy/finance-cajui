import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_reply.dart';

/// Um modelo de mentira, que responde o que o teste mandar — inclusive o que
/// um modelo enganado por um comprovante malicioso responderia.
final class ScriptedChatClient extends ChatClient {
  /// Cria o cliente que responde [content], ou lança [failure] se houver.
  new({this.content = '{}', this.failure, this.delay = Duration.zero});

  /// O que o "modelo" responde.
  final String content;

  /// A exceção que ele lança em vez de responder.
  final Exception? failure;

  /// Quanto ele demora para responder.
  final Duration delay;

  /// Os pedidos recebidos: instruções e conteúdo de cada chamada.
  final List<({String system, String user})> calls = [];

  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) async {
    calls.add((system: system, user: user));
    await Future<void>.delayed(delay);
    final error = failure;
    if (error != null) throw error;
    return ChatReply(content: content, promptTokens: 400, completionTokens: 40);
  }
}
