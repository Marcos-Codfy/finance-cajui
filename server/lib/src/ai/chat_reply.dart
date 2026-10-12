import 'package:meta/meta.dart';
import 'package:server/src/ai/tool_call.dart';

/// A resposta de um modelo de linguagem: o texto, as ferramentas que ele
/// pediu e quanto custou.
@immutable
final class ChatReply {
  /// Cria a resposta.
  const new({
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
    this.toolCalls = const [],
    this.truncated = false,
  });

  /// Se o modelo parou porque bateu no teto de tokens da resposta
  /// (`finish_reason` "length"): o texto acabou no meio, e um JSON cortado
  /// não se lê inteiro (RN-1103, BL-078).
  final bool truncated;

  /// O texto devolvido. É **entrada não confiável**: só vira alguma coisa
  /// depois de passar por quem o lê.
  final String content;

  /// As ferramentas que o modelo pediu antes de responder; vazio quando a
  /// resposta é o texto.
  final List<ToolCall> toolCalls;

  /// Se o modelo parou para pedir ferramentas.
  bool get wantsTools => toolCalls.isNotEmpty;

  /// Os tokens de entrada cobrados.
  final int promptTokens;

  /// Os tokens de saída cobrados.
  final int completionTokens;

  /// O total cobrado, para o orçamento do mês.
  int get totalTokens => promptTokens + completionTokens;
}
