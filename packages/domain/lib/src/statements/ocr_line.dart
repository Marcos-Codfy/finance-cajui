/// Uma linha de extrato lida pelo OCR, com os números consertados.
///
/// O OCR do celular lê o texto do banco quase sempre certo, mas às vezes
/// quebra um número: a vírgula dos centavos sai dobrada ("+3.120,,00"), o
/// valor ganha um espaço no meio ("-32, 80"), a data também ("11/ 10").
/// Com o número quebrado, o valor não é achado na linha: o servidor recusa
/// a movimentação que a IA leu certo, e a linha some calada. Visto no S22 em
/// 12/10, com um extrato fictício em PDF: a TED recebida e uma farmácia
/// ficaram de fora assim.
///
/// Só junta o que estava separado por engano; não inventa dígito.
abstract final class OcrLine {
  /// [line] com o valor e a data juntos de novo.
  static String tidy(String line) => line
      .replaceAllMapped(_splitCents, (match) => '${match[1]},${match[2]}')
      .replaceAllMapped(_splitDate, (match) => '${match[1]}/${match[2]}');

  /// Um valor cuja vírgula dos centavos veio repetida ou com espaço. O
  /// número da esquerda não pode vir colado a outra vírgula ou dígito: em
  /// "12,00, 13,00" nada se junta.
  static final _splitCents = RegExp(
    r'(?<![,\d])(\d{1,3}(?:\.\d{3})+|\d+)\s*,[\s,]*(\d{2})(?!\d)',
  );

  /// A barra de uma data com espaço em volta.
  static final _splitDate = RegExp(r'(\d)\s*/\s*(\d)');
}
