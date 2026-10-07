import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_tool.dart';

/// Um "modelo" que sabe pedir ferramentas: devolve as respostas de [replies]
/// na ordem, uma por chamada — a última se repete —, e guarda cada conversa
/// e cada lista de ferramentas oferecida, para o teste conferir o que o
/// servidor mandou e o que ele fez com o resultado.
final class ToolChatClient extends ChatClient {
  /// Cria o cliente com as respostas [replies].
  new(this.replies);

  /// As respostas, na ordem em que saem.
  final List<ChatReply> replies;

  /// As conversas recebidas, uma por chamada, como foram enviadas.
  final List<List<ChatMessage>> conversations = [];

  /// As ferramentas oferecidas em cada chamada.
  final List<List<ChatTool>> offered = [];

  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) => converse(
    messages: [ChatMessage.system(system), ChatMessage.user(user)],
    maxTokens: maxTokens,
  );

  @override
  Future<ChatReply> converse({
    required List<ChatMessage> messages,
    required int maxTokens,
    List<ChatTool> tools = const [],
  }) async {
    conversations.add(List.of(messages));
    offered.add(tools);
    final index = conversations.length - 1;
    return index < replies.length ? replies[index] : replies.last;
  }
}
