import 'package:meta/meta.dart';

/// A resposta de um modelo de linguagem: o texto e quanto custou.
@immutable
final class ChatReply {
  /// Cria a resposta.
  const new({
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
  });

  /// O texto devolvido. É **entrada não confiável**: só vira alguma coisa
  /// depois de passar pelo validador.
  final String content;

  /// Os tokens de entrada cobrados.
  final int promptTokens;

  /// Os tokens de saída cobrados.
  final int completionTokens;

  /// O total cobrado, para o orçamento do mês.
  int get totalTokens => promptTokens + completionTokens;
}
