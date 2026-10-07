import 'dart:convert';
import 'dart:io';

import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/tool_call.dart';

/// O adaptador da DeepSeek (ADR-010).
///
/// A chave da API existe **só aqui**, no servidor, e chega por arquivo de
/// credencial — nunca por variável de ambiente, nunca no app, nunca no
/// repositório (RNF-SEC-11 · T-27). Nada do que trafega é registrado: nem o
/// pedido, nem a resposta, nem a chave.
final class DeepSeekChatClient extends ChatClient {
  /// Cria o cliente com a chave da API, já lida da credencial.
  new({required this._apiKey, HttpClient? httpClient})
    : _http = httpClient ?? HttpClient() {
    _http.connectionTimeout = const Duration(seconds: 5);
  }

  /// O nome da credencial que o systemd entrega ao serviço.
  static const credentialName = 'cajui-deepseek-key';

  /// O modelo leve: responde em segundos e sabe pedir ferramentas.
  static const model = 'deepseek-flash';

  static final Uri _endpoint = Uri.https(
    'api.deepseek.com',
    '/chat/completions',
  );

  final String _apiKey;
  final HttpClient _http;

  /// Saída em JSON, temperatura zero, teto de tokens e **sem o modo de
  /// raciocínio**: a tarefa é escolher numa lista, e o modo padrão gastaria
  /// tokens e tempo contra o prazo de 8 s. Sem ferramentas: classificar não
  /// executa nada (RN-776).
  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) => _send({
    'model': model,
    'messages': [
      {'role': 'system', 'content': system},
      {'role': 'user', 'content': user},
    ],
    'response_format': {'type': 'json_object'},
    'thinking': {'type': 'disabled'},
    'temperature': 0,
    'max_tokens': maxTokens,
  });

  /// A conversa inteira vai a cada chamada — o provedor reaproveita o
  /// prefixo —, e as ferramentas vão descritas junto. Um pouco de
  /// temperatura para redigir; nenhuma para ler um comprovante, que é
  /// pergunta de resposta certa, em JSON.
  @override
  Future<ChatReply> converse({
    required List<ChatMessage> messages,
    required int maxTokens,
    List<ChatTool> tools = const [],
    bool json = false,
  }) => _send({
    'model': model,
    'messages': [for (final message in messages) message.toJson()],
    if (tools.isNotEmpty) 'tools': [for (final tool in tools) tool.toJson()],
    if (json) 'response_format': {'type': 'json_object'},
    'thinking': {'type': 'disabled'},
    'temperature': json ? 0 : 0.3,
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
        ..headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey')
        ..write(jsonEncode(body));
      response = await request.close();
    } on IOException {
      throw const ChatUnavailable();
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      final wait = int.tryParse(response.headers.value('retry-after') ?? '');
      throw ChatUnavailable(retryAfterSeconds: wait);
    }
    return _reply(await response.transform(utf8.decoder).join());
  }

  /// Com ferramentas pedidas o texto costuma vir nulo: vale vazio, e quem
  /// lê olha os pedidos.
  ChatReply _reply(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      final choice = (json['choices']! as List<Object?>).first;
      final message = (choice! as Map<String, Object?>)['message'];
      final fields = message! as Map<String, Object?>;
      final usage = json['usage']! as Map<String, Object?>;
      return ChatReply(
        content: '${fields['content'] ?? ''}',
        toolCalls: [
          for (final raw in fields['tool_calls'] as List<Object?>? ?? const [])
            ?ToolCall.tryParse(raw),
        ],
        promptTokens: usage['prompt_tokens']! as int,
        completionTokens: usage['completion_tokens']! as int,
      );
    } on Object {
      throw const ChatUnavailable();
    }
  }
}
