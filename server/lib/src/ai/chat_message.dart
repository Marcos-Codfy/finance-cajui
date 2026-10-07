import 'package:meta/meta.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/tool_call.dart';

/// Uma mensagem de uma conversa com o modelo, no formato que o provedor
/// entende: quem falou, o que disse e, no caso do modelo, que ferramentas
/// pediu — ou, no caso de uma ferramenta, a que pedido ela responde.
///
/// A mensagem da pessoa pode levar imagens (ADR-022): a foto do comprovante
/// vai junto do texto que o celular leu dela, na mesma mensagem.
@immutable
final class ChatMessage {
  const new _(
    this.role,
    this.content, {
    this.toolCallId,
    this.toolCalls = const [],
    this.images = const [],
  });

  /// Instruções do servidor.
  const new system(String content) : this._(ChatRole.system, content);

  /// O que a pessoa disse — e as imagens que mostrou, como endereços de
  /// dados (`data:image/jpeg;base64,…`).
  const new user(String content, {List<String> images = const []})
    : this._(ChatRole.user, content, images: images);

  /// O que o modelo disse — e as ferramentas que pediu, se pediu.
  const new assistant(String content, {List<ToolCall> toolCalls = const []})
    : this._(ChatRole.assistant, content, toolCalls: toolCalls);

  /// O resultado da ferramenta que atendeu o pedido [toolCallId].
  const new tool(String content, {required String toolCallId})
    : this._(ChatRole.tool, content, toolCallId: toolCallId);

  /// Quem fala.
  final ChatRole role;

  /// O texto.
  final String content;

  /// O pedido a que uma ferramenta responde.
  final String? toolCallId;

  /// As ferramentas que o modelo pediu nesta mensagem.
  final List<ToolCall> toolCalls;

  /// As imagens da mensagem, como endereços de dados.
  final List<String> images;

  /// A mensagem como vai para o provedor. Com imagem, o conteúdo vira uma
  /// lista de partes: o texto primeiro, depois cada imagem.
  Map<String, Object?> toJson() => {
    'role': role.name,
    'content': images.isEmpty ? content : _parts,
    if (toolCallId != null) 'tool_call_id': toolCallId,
    if (toolCalls.isNotEmpty)
      'tool_calls': [for (final call in toolCalls) call.toJson()],
  };

  List<Map<String, Object?>> get _parts => [
    {'type': 'text', 'text': content},
    for (final image in images)
      {
        'type': 'image_url',
        'image_url': {'url': image},
      },
  ];
}
