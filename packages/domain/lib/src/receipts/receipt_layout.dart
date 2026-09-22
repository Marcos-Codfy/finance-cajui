/// Põe o texto de um comprovante em forma de leitura humana.
///
/// O OCR devolve a folha achatada: espaços a mais, linhas partidas no meio de
/// um item, sobras de coluna. Quem quer conferir o que o app leu precisa
/// reconhecer o comprovante ali — então aqui as linhas são limpas e agrupadas,
/// **sem nada ser inventado nem reordenado**: a ordem é a do papel.
abstract final class ReceiptLayout {
  /// Espaço repetido, que no cupom é coluna e na tela é buraco.
  static final _runs = RegExp(r'[ \t]{2,}');

  /// Linha que o OCR devolveu só com sobra de coluna ou traço de separação.
  static final _noise = RegExp(r'^[\s\-_=.|]*$');

  /// Continuação de um item cortado: começa em minúscula ou em unidade, e a
  /// linha de cima não terminou em número.
  static final _continues = RegExp(
    r'^(?:[a-zà-ú]|\d+[,.]\d+\s*(?:kg|g|ml|l)\b)',
  );

  /// As linhas de [text] prontas para ler: sem ruído, sem espaço duplicado e
  /// com a continuação de um item colada na linha dele.
  static List<String> lines(String text) {
    final cleaned = [
      for (final line in text.split('\n')) line.replaceAll(_runs, ' ').trim(),
    ].where((line) => line.isNotEmpty && !_noise.hasMatch(line));
    final joined = <String>[];
    for (final line in cleaned) {
      if (joined.isNotEmpty && _isWrap(joined.last, line)) {
        joined[joined.length - 1] = '${joined.last} $line';
      } else {
        joined.add(line);
      }
    }
    return joined;
  }

  /// Mesmo texto, em uma string pronta para um bloco de leitura.
  static String readable(String text) => lines(text).join('\n');

  /// Se [line] é a sobra da linha anterior, e não uma linha nova. Linha
  /// curta demais para ser item, começando em minúscula, é sobra.
  static bool _isWrap(String previous, String line) =>
      _continues.hasMatch(line) &&
      line.length <= _wrapLength &&
      !previous.endsWith(':');

  static const _wrapLength = 28;
}
