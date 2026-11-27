/// Como a busca compara textos: minúsculas, sem acento e com um espaço só
/// entre as palavras — "Padaria  São João" acha "sao joao".
///
/// Não é a normalização do domínio (`PossibleDuplicate.normalize`): aquela
/// tira número e "Ltda." porque compara estabelecimentos, e quem busca
/// "99" ou "ltda" quer achar exatamente isso.
abstract final class SearchFold {
  /// As letras com acento que se escrevem em português, e as poucas de nome
  /// estrangeiro que aparecem em comprovante.
  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };

  static final _spaces = RegExp(r'\s+');

  /// [text] dobrado para comparar.
  static String of(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(_spaces, ' ').trim();
  }
}
