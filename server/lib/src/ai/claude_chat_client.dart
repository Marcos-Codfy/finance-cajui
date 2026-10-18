import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/claude_messages.dart';

/// A IA pela API da Anthropic (Claude), ao lado da DeepSeek (18/10/2026): o
/// dono quis usar o Claude por um dia e voltar. Quem escolhe é a credencial
/// instalada na VM — com a do Claude, ela vale; sem, a DeepSeek, como antes
/// (ver `bin/server.dart`). As outras peças não sabem qual das duas fala.
final class ClaudeChatClient extends ChatClient {
  /// Cria o cliente com a chave [_apiKey].
  new({required this._apiKey, HttpClient? httpClient})
    : _http = httpClient ?? HttpClient() {
    _http.connectionTimeout = const Duration(seconds: 5);
  }

  /// O nome da credencial do systemd que guarda a chave.
  static const credentialName = 'cajui-claude-key';

  /// O modelo que o dono escolheu: o Sonnet 5.5, com esforço médio.
  static const model = 'claude-sonnet-5-5';

  /// O que todo pedido leva. O Sonnet 5.5 recusa `temperature` (400). O
  /// raciocínio fica desligado — no 5.5 isso é `between_tools`, e não
  /// `disabled`, que dá 400 —: ligado, a conversa com ferramentas teria de
  /// devolver os blocos de raciocínio da resposta anterior, e a conversa do
  /// Cajui não os guarda. O esforço médio vale para a resposta.
  static const Map<String, Object?> _settings = {
    'thinking': {'type': 'between_tools'},
    'output_config': {'effort': 'medium'},
  };

  static final Uri _endpoint = Uri.https('api.anthropic.com', '/v1/messages');

  final String _apiKey;
  final HttpClient _http;

  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) => _send({
    'model': model,
    'system': system,
    'messages': [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': user},
        ],
      },
    ],
    ..._settings,
    'max_tokens': maxTokens,
  });

  @override
  Future<ChatReply> converse({
    required List<ChatMessage> messages,
    required int maxTokens,
    List<ChatTool> tools = const [],
    bool json = false,
  }) => _send({
    'model': model,
    'system': ClaudeMessages.systemOf(messages),
    'messages': ClaudeMessages.of(messages),
    if (tools.isNotEmpty) 'tools': ClaudeMessages.toolsOf(tools),
    ..._settings,
    'max_tokens': maxTokens,
  });

  Future<ChatReply> _send(Map<String, Object?> body) async {
    final HttpClientResponse response;
    try {
      final request = await _http.postUrl(_endpoint);
      // Redirecionamento não é seguido: a chave não vai para onde o servidor
      // mandar (ASVS 15.3.2).
      request
        ..followRedirects = false
        ..headers.contentType = ContentType.json
        ..headers.set('x-api-key', _apiKey)
        ..headers.set('anthropic-version', '2023-06-01')
        ..write(jsonEncode(body));
      response = await request.close();
    } on IOException {
      throw const ChatUnavailable();
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      // Só o número: o corpo pode repetir o pedido, e o pedido tem o
      // comprovante.
      stderr.writeln('IA: o provedor respondeu HTTP ${response.statusCode}');
      final wait = int.tryParse(response.headers.value('retry-after') ?? '');
      throw ChatUnavailable(
        retryAfterSeconds: wait,
        status: response.statusCode,
      );
    }
    return replyOf(await response.transform(utf8.decoder).join());
  }

  /// Lê a resposta [body]; qualquer coisa fora do formato é IA fora do ar.
  @visibleForTesting
  static ChatReply replyOf(String body) {
    try {
      return ClaudeMessages.replyOf(jsonDecode(body) as Map<String, Object?>);
    } on Object {
      throw const ChatUnavailable();
    }
  }
}
