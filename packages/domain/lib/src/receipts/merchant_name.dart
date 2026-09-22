/// Deixa o nome do estabelecimento com cara de nome.
///
/// Cupom fiscal escreve a razão social inteira em maiúsculas — "WNS
/// SUPERMERCADOS DO BRASIL LTDA" —, e é isso que o leitor extrai. Na tela,
/// texto todo em maiúsculas lê pior e parece grito (guia de voz): aqui a
/// forma jurídica sai e o resto vira capitulação normal.
abstract final class MerchantName {
  /// A forma jurídica no fim do nome: não é parte de como a loja se chama.
  static final _legalForm = RegExp(
    // "LTEA", "LTDA." e "LTDA-ME" são o que o OCR devolve de "LTDA".
    r'[\s,-]+(?:lt[deo]a|ltd|eireli|epp|mei|me|s\.?\s?/?\s?a)\.?'
    r'(?:[\s-]+me)?\.?\s*$',
    caseSensitive: false,
  );

  /// Palavras que ficam minúsculas no meio do nome.
  static const _connectives = {'de', 'da', 'do', 'das', 'dos', 'e'};

  static final _vowel = RegExp('[aeiouáéíóúâêôãõà]', caseSensitive: false);

  /// [raw] pronto para a tela; `null` quando não sobra nome nenhum.
  static String? pretty(String? raw) {
    final trimmed = raw?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (trimmed.isEmpty) return null;
    final withoutForm = trimmed.replaceFirst(_legalForm, '').trim();
    final name = withoutForm.isEmpty ? trimmed : withoutForm;
    if (!_isShouting(name)) return name;
    final words = name.split(' ').indexed.map(_cased);
    return words.join(' ');
  }

  /// Só mexe no que está gritando: nome já escrito normalmente fica como a
  /// pessoa (ou o banco) escreveu.
  static bool _isShouting(String name) => name == name.toUpperCase();

  static String _cased((int, String) word) {
    final (index, text) = word;
    final lower = text.toLowerCase();
    // Sigla — "WNS", "JJ" — continua em maiúsculas: capitular esconderia que
    // é sigla.
    if (!_vowel.hasMatch(text)) return text;
    if (index > 0 && _connectives.contains(lower)) return lower;
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
