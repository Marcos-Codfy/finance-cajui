import 'dart:convert';

import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/cut_reply.dart';

/// O que uma resposta da IA a uma página rendeu, antes da conferência: os
/// itens crus, o período escrito e se ela veio cortada.
typedef StatementAnswerParts = ({
  List<Object?> items,
  String? period,
  bool cut,
});

/// Abre a resposta da IA a uma página de extrato (ADR-030).
///
/// A resposta inteira precisa estar no esquema — campo desconhecido ou de
/// tipo errado a deixa de fora (RN-773). A cortada pelo teto de tokens não
/// tem como estar: dela se aproveita o que veio completo (RN-1103).
abstract final class StatementAnswer {
  static const _fields = {'period', 'lines'};

  /// As partes de [reply]; `null` quando a resposta, sem corte, não se
  /// aproveita.
  static StatementAnswerParts? of(ChatReply reply) {
    if (reply.truncated) {
      return (
        items: CutReply.objectsIn(reply.content, 'lines'),
        period: CutReply.textIn(reply.content, 'period'),
        cut: true,
      );
    }
    return _whole(reply.content);
  }

  /// As partes das [halves] — as duas metades da página, relidas depois do
  /// corte —, sendo [numbers] as linhas de cada uma. Metade fora do esquema
  /// fica com o que a resposta cortada [cut] já trouxe completo dessas
  /// linhas; se as duas vieram fora, vale a cortada inteira. A releitura
  /// existe para render mais, nunca menos: antes, duas metades ruins
  /// jogavam fora movimentações que já tinham chegado inteiras. O que vem
  /// da cortada marca a página como lida em parte (RN-1103).
  static List<StatementAnswerParts?> ofHalves(
    List<ChatReply> halves,
    List<List<int>> numbers,
    ChatReply cut,
  ) {
    final answers = [for (final half in halves) of(half)];
    final fallback = of(cut);
    if (answers.every((parts) => parts == null)) return [fallback];
    return [
      for (final (index, parts) in answers.indexed)
        parts ?? _within(fallback, numbers[index].toSet()),
    ];
  }

  /// Só os itens de [parts] que citam uma das [lines], como resposta
  /// cortada: o que ficou de fora delas não é sabido.
  static StatementAnswerParts? _within(
    StatementAnswerParts? parts,
    Set<int> lines,
  ) {
    if (parts == null) return null;
    return (
      items: [
        for (final item in parts.items)
          if (item is Map<String, Object?> && lines.contains(item['line']))
            item,
      ],
      period: parts.period,
      cut: true,
    );
  }

  /// Um modelo que embrulha o JSON em bloco de código ainda é lido: vale o
  /// trecho entre a primeira e a última chave.
  static StatementAnswerParts? _whole(String content) {
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final json = jsonDecode(content.substring(start, end + 1));
      if (json is! Map<String, Object?>) return null;
      if (json.keys.any((key) => !_fields.contains(key))) return null;
      final (items, period) = (json['lines'], json['period']);
      if (items is! List<Object?>? || period is! String?) return null;
      return (items: items ?? const [], period: period, cut: false);
    } on FormatException {
      return null;
    }
  }
}
