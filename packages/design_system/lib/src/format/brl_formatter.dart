/// Escreve centavos como valor em reais, do jeito que o guia de voz pede.
///
/// Trabalha com inteiros de centavos de ponta a ponta — o design system nunca
/// vê um `double` de dinheiro (RN-101). E não depende de pacote de
/// internacionalização: o app tem uma moeda só, e a regra cabe em poucas
/// linhas que dá para testar caso a caso.
abstract final class BrlFormatter {
  /// Espaço que não quebra linha (U+00A0): "R$" nunca fica sozinho no fim da
  /// linha. Escrito como escape para não ficar invisível no código.
  static const nbsp = '\u00A0';

  /// Sinal de menos verdadeiro (U+2212), não hífen.
  static const minus = '\u2212';

  /// Formata [cents] como "R$ 1.284,50".
  ///
  /// Com [hideZeroCents], omite os centavos quando são zero — o caso do
  /// número-manchete: "Sobram R$ 412".
  static String format(int cents, {bool hideZeroCents = false}) {
    final sign = cents < 0 ? minus : '';
    final value = number(cents, hideZeroCents: hideZeroCents);
    return '${sign}R\$$nbsp$value';
  }

  /// Só o número, sem "R$" e sem sinal: "1.284,50".
  static String number(int cents, {bool hideZeroCents = false}) {
    final absolute = cents.abs();
    final whole = _groupThousands(absolute ~/ 100);
    final fraction = absolute % 100;
    if (hideZeroCents && fraction == 0) return whole;
    return '$whole,${fraction.toString().padLeft(2, '0')}';
  }

  static String _groupThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
