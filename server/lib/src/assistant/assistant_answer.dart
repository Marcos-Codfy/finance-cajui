import 'package:meta/meta.dart';
import 'package:server/src/assistant/assistant_action.dart';

/// A resposta do assistente, como vai para o app: o texto, e o que ele fez
/// no livro enquanto respondia.
///
/// O texto é da IA, e é texto: a tela o mostra puro, sem link e sem
/// formatação (RN-948). O que não cabe — vazio, longo demais — vira a
/// resposta de formato fixo, para a conversa nunca ficar muda.
@immutable
final class AssistantAnswer {
  /// Cria a resposta.
  const new({
    required this.text,
    this.actions = const [],
    this.isFallback = false,
  });

  /// A resposta de formato fixo, para quando a IA não conseguiu responder
  /// — o que ela já tiver feito no livro continua feito, e é dito.
  factory fallback({List<AssistantAction> actions = const []}) =>
      AssistantAnswer(
        isFallback: true,
        actions: actions,
        text: actions.isEmpty
            ? 'Não consegui responder agora. Tente de novo em instantes.'
            : 'Fiz o que você pediu, mas não consegui redigir a resposta. '
                  'Confira em Lançamentos.',
      );

  /// O teto do texto. Resposta de conversa é curta; o que passa disto é
  /// cortado, e não recusado.
  static const maxLength = 1200;

  /// O texto para a tela.
  final String text;

  /// O que o assistente fez no livro nesta resposta.
  final List<AssistantAction> actions;

  /// Se é a resposta de formato fixo.
  final bool isFallback;

  /// A resposta a partir de [content], o texto cru da IA, ou `null` quando
  /// não há texto nenhum.
  static AssistantAnswer? fromText(
    String content, {
    List<AssistantAction> actions = const [],
  }) {
    final text = plain(content);
    if (text.isEmpty) return null;
    return AssistantAnswer(
      text: text.length > maxLength ? text.substring(0, maxLength) : text,
      actions: actions,
    );
  }

  /// O texto sem as marcas de formatação que o modelo às vezes põe:
  /// negrito, título, código. A tela não as interpreta, e exibi-las seria
  /// mostrar asteriscos.
  static String plain(String content) => content
      .replaceAll(RegExp(r'\*{1,3}'), '')
      .replaceAll(RegExp('`{1,3}'), '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .trim();

  /// A resposta como vai para o app. `sources` e `outOfScope` continuam
  /// no contrato, vazios: o app de ontem os lê sem tropeçar.
  Map<String, Object?> toJson() => {
    'text': text,
    'outOfScope': false,
    'fallback': isFallback,
    'sources': const <Object?>[],
    'actions': [for (final action in actions) action.toJson()],
  };
}
