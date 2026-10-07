import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_reply.dart';

/// Um "modelo" que devolve uma resposta por chamada, na ordem dada; a última
/// se repete. Serve para ensaiar a nova tentativa depois de uma reprovação.
final class SequencedChatClient extends ChatClient {
  /// Cria o cliente com as respostas [contents].
  new(this.contents, {this.failure});

  /// As respostas, na ordem em que saem.
  final List<String> contents;

  /// Se dada, toda chamada falha com ela.
  final Exception? failure;

  /// O que foi pedido a cada chamada.
  final List<({String system, String user})> calls = [];

  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) async {
    calls.add((system: system, user: user));
    final error = failure;
    if (error != null) throw error;
    final index = calls.length <= contents.length ? calls.length - 1 : null;
    return ChatReply(
      content: index == null ? contents.last : contents[index],
      promptTokens: 900,
      completionTokens: 80,
    );
  }
}
