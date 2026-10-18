import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/tool_call.dart';

/// A tradução entre a conversa do Cajui — no formato da DeepSeek, que é o
/// das outras peças — e a API de mensagens da Anthropic.
///
/// As diferenças que importam: o sistema vai à parte; a resposta de uma
/// ferramenta é uma mensagem *do usuário* com `tool_result`; papéis iguais
/// seguidos precisam virar uma mensagem só; e a imagem vai em base64, e não
/// como endereço de dados.
abstract final class ClaudeMessages {
  /// O texto de sistema de [messages], junto.
  static String systemOf(List<ChatMessage> messages) => [
    for (final message in messages)
      if (message.role == ChatRole.system) message.content,
  ].join('\n');

  /// As mensagens de [messages] sem o sistema, já no formato da Anthropic.
  static List<Map<String, Object?>> of(List<ChatMessage> messages) {
    final out = <Map<String, Object?>>[];
    for (final message in messages) {
      if (message.role == ChatRole.system) continue;
      final role = message.role == ChatRole.assistant ? 'assistant' : 'user';
      final blocks = _blocks(message);
      if (out.isNotEmpty && out.last['role'] == role) {
        (out.last['content']! as List<Map<String, Object?>>).addAll(blocks);
      } else {
        out.add({'role': role, 'content': blocks});
      }
    }
    return out;
  }

  static List<Map<String, Object?>> _blocks(ChatMessage message) => [
    if (message.role == ChatRole.tool)
      {
        'type': 'tool_result',
        'tool_use_id': message.toolCallId,
        'content': message.content,
      }
    else if (message.content.isNotEmpty)
      {'type': 'text', 'text': message.content},
    for (final image in message.images) ?_image(image),
    for (final call in message.toolCalls)
      {
        'type': 'tool_use',
        'id': call.id,
        'name': call.name,
        'input': call.arguments,
      },
  ];

  static final _dataUrl = RegExp(r'^data:([^;]+);base64,(.+)$');

  /// "data:image/jpeg;base64,AAAA" vira o bloco de imagem da Anthropic.
  static Map<String, Object?>? _image(String dataUrl) {
    final match = _dataUrl.firstMatch(dataUrl);
    if (match == null) return null;
    return {
      'type': 'image',
      'source': {'type': 'base64', 'media_type': match[1], 'data': match[2]},
    };
  }

  /// As ferramentas no formato da Anthropic.
  static List<Map<String, Object?>> toolsOf(List<ChatTool> tools) => [
    for (final tool in tools)
      {
        'name': tool.name,
        'description': tool.description,
        'input_schema': tool.parameters,
      },
  ];

  /// A resposta da Anthropic como o Cajui a entende.
  static ChatReply replyOf(Map<String, Object?> json) {
    final blocks = (json['content']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final usage = json['usage']! as Map<String, Object?>;
    return ChatReply(
      content: [
        for (final block in blocks)
          if (block['type'] == 'text') '${block['text']}',
      ].join(),
      toolCalls: [
        for (final block in blocks)
          if (block['type'] == 'tool_use') _call(block),
      ],
      promptTokens: usage['input_tokens']! as int,
      completionTokens: usage['output_tokens']! as int,
      truncated: json['stop_reason'] == 'max_tokens',
    );
  }

  static ToolCall _call(Map<String, Object?> block) => ToolCall(
    id: '${block['id']}',
    name: '${block['name']}',
    arguments: (block['input'] as Map? ?? const {}).cast<String, Object?>(),
  );
}
