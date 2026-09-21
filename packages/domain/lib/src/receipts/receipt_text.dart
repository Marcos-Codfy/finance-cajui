/// O texto de um comprovante, limpo do que não é conteúdo.
///
/// O texto vem de um papel que qualquer pessoa pode ter escrito, e é tratado
/// como **entrada não confiável** do começo ao fim. A limpeza acontece antes
/// de tudo — da leitura das regras, do mascaramento e de qualquer envio.
abstract final class ReceiptText {
  /// O maior texto aproveitado. Um comprovante tem algumas centenas de
  /// caracteres; um extrato longo, alguns milhares. O resto é enchimento —
  /// às vezes posto ali para gastar tokens (caso INJ-05).
  static const maxLength = 8000;

  /// Caracteres invisíveis e de controle: marcas de direção de texto,
  /// espaços de largura zero, BOM. São o que esconde uma instrução dentro de
  /// um comprovante de aparência inocente.
  static final _invisible = RegExp(
    '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F'
    '\u00AD\u200B-\u200F\u202A-\u202E\u2060-\u2064\uFEFF]',
  );

  static final _blankRuns = RegExp('[ \t]+');
  static final _emptyLines = RegExp(r'\n{3,}');

  /// O texto sem caracteres invisíveis, com os espaços arrumados e cortado em
  /// [maxLength].
  static String clean(String raw) {
    final visible = raw
        .replaceAll('\r\n', '\n')
        .replaceAll(_invisible, '')
        .replaceAll(_blankRuns, ' ')
        .replaceAll(_emptyLines, '\n\n')
        .trim();
    return visible.length <= maxLength
        ? visible
        : visible.substring(0, maxLength);
  }
}
