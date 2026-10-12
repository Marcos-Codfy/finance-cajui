/// Se um texto lido tem cara de extrato: várias linhas que começam com a
/// data e trazem um valor (RN-1100).
///
/// Decide no celular, antes de qualquer IA. Assim o extrato vai direto para
/// a conversa com a Juju, lido página a página e mascarado no aparelho, sem
/// passar antes pela leitura de comprovante — que o cortava em 8.000
/// caracteres e o mandava à IA sem a máscara da ADR-030. Um cupom de
/// mercado tem muitos valores, mas as linhas dele não começam com data.
abstract final class StatementShape {
  /// Quantas linhas com data e valor bastam para ser extrato.
  static const minLines = 5;

  /// Com a palavra "extrato" no texto, bastam estas.
  static const minLinesNamed = 3;

  /// Se [text] parece um extrato.
  static bool looksLike(String text) {
    final upper = text.toUpperCase();
    final dated = upper
        .split('\n')
        .where(
          (line) => _startsWithDate.hasMatch(line) && _amount.hasMatch(line),
        )
        .length;
    final named = upper.contains('EXTRATO') || upper.contains('FATURA');
    return dated >= (named ? minLinesNamed : minLines);
  }

  /// "05/10", "5/10/2026", "05 OUT", "05-10" no começo da linha.
  static final _startsWithDate = RegExp(
    r'^\s*\d{1,2}(?:[/.-]\d{1,2}(?:[/.-]\d{2,4})?|\s?(?:JAN|FEV|MAR|ABR|MAI|JUN|JUL|AGO|SET|OUT|NOV|DEZ))\b',
  );

  /// Um valor com centavos: "12,50", "1.200,00", "-45,90".
  static final _amount = RegExp(r'\d,\d{2}\b');
}
