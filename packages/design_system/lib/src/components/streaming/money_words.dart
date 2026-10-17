import 'dart:ui' show FontVariation;

/// Os valores em reais de uma resposta, em destaque (17/10/2026): na frase
/// da Juju, "R$ 530,90" se lê de relance no meio das palavras.
///
/// Trabalha sobre as palavras como a fala chega (`words`), para o destaque
/// valer igual na resposta que ainda está chegando e na que já chegou.
abstract final class MoneyWords {
  /// Cada palavra com o espaço dela, na ordem da frase.
  static final RegExp words = RegExp(r'\s*\S+\s*');

  static final _amount = RegExp(r'^-?\d{1,3}(?:\.\d{3})*,\d{2}');
  static const _symbol = r'R$';

  /// O peso do valor em destaque.
  static const List<FontVariation> weight = [FontVariation('wght', 650)];

  /// As palavras de [text].
  static List<String> split(String text) => [
    for (final match in words.allMatches(text)) match[0]!,
  ];

  /// Se a palavra [index] de [list] é parte de um valor: o "R$" seguido de
  /// número, ou o número logo depois do "R$".
  static bool isMoney(List<String> list, int index) {
    final word = list[index].trim();
    if (word == _symbol || word == '-$_symbol') {
      return index + 1 < list.length &&
          _amount.hasMatch(list[index + 1].trim());
    }
    if (word.startsWith(_symbol)) {
      return _amount.hasMatch(word.substring(_symbol.length).trim());
    }
    return index > 0 &&
        list[index - 1].trim().endsWith(_symbol) &&
        _amount.hasMatch(word);
  }
}
