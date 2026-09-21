import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:server/src/assistant/assistant_context.dart';
import 'package:server/src/assistant/context_number.dart';

/// A resposta do assistente, **depois** de validada (RN-942 a RN-944).
///
/// A saída da IA é entrada não confiável como qualquer outra. Só vira
/// resposta o que passa, nesta ordem, por: esquema fechado; texto puro e
/// dentro do tamanho; todo valor em reais existir no contexto ou na pergunta;
/// nenhum termo que o guia de voz reprova.
@immutable
final class AssistantAnswer {
  /// Cria a resposta já validada.
  const new({
    required this.text,
    required this.sources,
    this.outOfScope = false,
    this.isFallback = false,
  });

  /// A resposta de formato fixo, para quando a IA reprovou duas vezes: os
  /// números que o servidor encontrou, sem uma palavra da IA (RN-945).
  factory fallback(AssistantContext context) {
    final found = context.numbers
        .take(_fallbackNumbers)
        .map((n) => '${n.label}: ${MoneyFormat.brl(n.amount)}')
        .join(' · ');
    return AssistantAnswer(
      isFallback: true,
      sources: context.numbers.take(_fallbackNumbers).toList(),
      text: found.isEmpty
          ? 'Não consegui redigir uma resposta confiável, e ainda não há '
                'lançamentos neste mês para eu mostrar.'
          : 'Não consegui redigir uma resposta confiável. Os números que '
                'encontrei: $found.',
    );
  }

  /// Quantos números a resposta de formato fixo traz.
  static const _fallbackNumbers = 4;

  /// O texto para a tela. É exibido como texto puro: nenhum endereço vindo
  /// da IA vira link (RN-948).
  final String text;

  /// Os números citados — é daqui, e não do texto da IA, que a tela monta
  /// "De onde vieram os números" (RN-947).
  final List<ContextNumber> sources;

  /// Se a pergunta ficou fora do que o assistente faz (RN-902).
  final bool outOfScope;

  /// Se é a resposta de formato fixo, montada sem texto da IA (RN-945).
  final bool isFallback;

  /// O teto do texto.
  static const maxLength = 600;

  static const _fields = {'text', 'sources', 'outOfScope'};
  static final _amount = RegExp(r'\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2}');

  /// A resposta contida em [content], a saída crua da IA, ou `null` se ela
  /// reprova em qualquer validação. [question] é a pergunta de quem usa: os
  /// valores que ela traz também podem ser citados.
  static AssistantAnswer? parse(
    String content, {
    required AssistantContext context,
    required String question,
  }) {
    final Object? json;
    try {
      json = jsonDecode(content);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    if (json.keys.any((key) => !_fields.contains(key))) return null;
    final (text, cited) = (json['text'], json['sources'] ?? const <Object?>[]);
    final scope = json['outOfScope'] ?? false;
    if (text is! String || cited is! List<Object?> || scope is! bool) {
      return null;
    }
    if (!_isAcceptable(text.trim(), context, question)) return null;
    return AssistantAnswer(
      text: text.trim(),
      outOfScope: scope,
      sources: [
        for (final id in cited.whereType<String>()) ?context.numberById(id),
      ],
    );
  }

  static bool _isAcceptable(
    String text,
    AssistantContext context,
    String question,
  ) {
    if (text.isEmpty || text.length > maxLength) return false;
    if (VoiceGuide.violations(text).isNotEmpty || text.contains('!')) {
      return false;
    }
    // Número que só existe no texto da IA não tem origem: reprova (RN-943).
    final allowed = {
      for (final number in context.numbers) number.amount,
      ...ReceiptFieldReader.amountsIn(question),
    };
    return _amount
        .allMatches(text)
        .map((match) => ReceiptFieldReader.amountsIn(match.group(0)!).single)
        .every(allowed.contains);
  }

  /// A resposta como vai para o app.
  Map<String, Object?> toJson() => {
    'text': text,
    'outOfScope': outOfScope,
    'fallback': isFallback,
    'sources': [for (final number in sources) number.toJson()],
  };
}
