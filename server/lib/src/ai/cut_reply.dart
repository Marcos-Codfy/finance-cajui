import 'dart:convert';

/// O que se aproveita de uma resposta da IA cortada no meio pelo teto de
/// tokens (RN-1103, BL-078).
///
/// Um JSON cortado não se lê de uma vez, e antes isso derrubava o extrato
/// inteiro. Aqui se lê o que veio **completo**: cada objeto da lista que
/// fechou a chave antes do corte. O que ficou no meio cai fora — e a
/// página sai marcada como lida em parte, nunca em silêncio.
abstract final class CutReply {
  /// Os objetos completos da lista [field] em [content], na ordem. Vazio
  /// quando a lista nem chegou a abrir.
  static List<Map<String, Object?>> objectsIn(String content, String field) {
    final open = content.indexOf('"$field"');
    if (open < 0) return const [];
    final list = content.indexOf('[', open);
    if (list < 0) return const [];
    return [
      for (final (from, to) in _spans(content, list + 1))
        ?_decoded(content.substring(from, to)),
    ];
  }

  /// O texto do campo [field] em [content], quando ele veio inteiro antes
  /// do corte; `null` se não veio, ou se não é texto.
  static String? textIn(String content, String field) {
    final match = RegExp(r'"(\w{1,20})"\s*:\s*"([^"\\]{0,40})"')
        .allMatches(content)
        .where((m) => m.group(1) == field)
        .firstOrNull;
    return match?.group(2);
  }

  /// Onde começa e onde termina cada objeto de primeiro nível da lista que
  /// abre em [from]. A lista acaba no `]` de primeiro nível, ou no corte.
  static List<(int, int)> _spans(String text, int from) {
    final spans = <(int, int)>[];
    final strings = _Strings();
    var depth = 0;
    var start = -1;
    for (var at = from; at < text.length; at++) {
      final char = strings.structural(text[at]);
      if (char == '{') {
        if (depth++ == 0) start = at;
      } else if (char == '}' && depth > 0) {
        if (--depth == 0) spans.add((start, at + 1));
      } else if (char == ']' && depth == 0) {
        break;
      }
    }
    return spans;
  }

  static Map<String, Object?>? _decoded(String object) {
    try {
      final decoded = jsonDecode(object);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

/// Quem sabe se o caractere da vez está dentro de um texto entre aspas: lá
/// dentro, chave e colchete são letras, não estrutura.
final class _Strings {
  var _inside = false;
  var _escaped = false;

  /// [char] quando ele conta para a estrutura; `null` dentro de um texto.
  String? structural(String char) {
    if (_escaped) {
      _escaped = false;
      return null;
    }
    if (!_inside) {
      if (char == '"') _inside = true;
      return char;
    }
    if (char == r'\') _escaped = true;
    if (char == '"') _inside = false;
    return null;
  }
}
