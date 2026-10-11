import 'package:domain/src/money/money.dart';

/// O texto de uma notificação de banco, do jeito que as regras o leem.
///
/// Cada banco escreve de um jeito — "APROVADA", "aprovada", "Aprovada!",
/// com acento ou sem, com espaço comum ou com o espaço fino que alguns apps
/// põem depois do "R$". As regras olham para uma forma só: minúsculas, sem
/// acento e com um espaço entre as palavras.
abstract final class NoticeText {
  static const _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  /// Espaço comum, quebra de linha e os dois espaços que não quebram:
  /// o comum (U+00A0) e o fino (U+202F), que alguns apps põem depois do "R$".
  static final _spaces = RegExp(
    '[\\s${String.fromCharCode(0xA0)}${String.fromCharCode(0x202F)}]+',
  );

  /// [text] em minúsculas, sem acento e com um espaço só entre as palavras.
  /// Pontuação e "R$" ficam: há regra que depende deles.
  static String fold(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(_spaces, ' ').trim();
  }

  /// [text] só com letras e dígitos: o que se compara com o nome de um
  /// cartão cadastrado.
  static String words(String text) =>
      fold(text).replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();

  /// [text] com um espaço comum só entre as palavras, na caixa original: o
  /// nome do estabelecimento sai daqui, como o banco o escreveu.
  static String plain(String text) => text.replaceAll(_spaces, ' ').trim();

  /// "R$ 1.234,56", "R$45,90", "R$ 10": milhar com ponto, centavo com
  /// vírgula, centavo opcional.
  static final _amount = RegExp(
    r'R\$\s?(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{2}))?(?!\d|,\d)',
    caseSensitive: false,
  );

  /// O valor da movimentação: o primeiro "R$" do texto que não é saldo nem
  /// limite. Itaú e Banco do Brasil põem o limite que sobrou logo depois da
  /// compra, e ele é maior que ela — pegar o maior valor erraria sempre.
  static Money? amountIn(String text) {
    final flat = plain(text);
    for (final match in _amount.allMatches(flat)) {
      if (_isBalance(flat, match.start)) continue;
      final whole = int.parse(match.group(1)!.replaceAll('.', ''));
      final cents = int.parse(match.group(2) ?? '0');
      return Money.fromCents(whole * 100 + cents);
    }
    return null;
  }

  static const _balanceWords = ['saldo', 'limite', 'disponivel'];

  /// O valor em [at] é saldo ou limite quando uma dessas palavras vem logo
  /// antes dele.
  static bool _isBalance(String text, int at) {
    final before = fold(text.substring(at < 24 ? 0 : at - 24, at));
    return _balanceWords.any(before.contains);
  }

  /// "final 1234", "terminado em 1234", "•••• 1234", "**** 1234".
  static final _cardDigits = RegExp(
    r'(?:final|terminado em|[•*.]{2,})\s*(\d{4})\b',
  );

  /// Os quatro últimos dígitos do cartão, quando a notificação os traz.
  static String? cardDigitsIn(String text) =>
      _cardDigits.firstMatch(fold(text))?.group(1);

  /// "em 3x", "3 x", "em 3 parcelas", "parcelada em 3".
  static final _installments = RegExp(
    r'\b(\d{1,2}) ?x\b|\b(\d{1,2}) parcelas\b|parcelad[ao] em (\d{1,2})\b',
  );

  /// Em quantas vezes a compra foi feita, quando a notificação diz que foi
  /// parcelada; `null` quando não diz.
  static int? installmentsIn(String text) {
    final match = _installments.firstMatch(fold(text));
    if (match == null) return null;
    final count = match.group(1) ?? match.group(2) ?? match.group(3);
    return int.parse(count!);
  }
}
