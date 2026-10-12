import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// As linhas de uma página de extrato, numeradas, nas duas versões: a
/// original, que fica no celular, e a mascarada, que vai ao servidor
/// (RN-730, RN-1106).
///
/// As duas têm o mesmo número de linhas, na mesma ordem. A IA cita a linha
/// pelo número, e é por ele que o celular acha o texto sem máscara — "Pix
/// para João P Silva" na pergunta, onde a IA só viu `[NOME]`.
@immutable
final class NumberedPage {
  /// Numera [text], sem as linhas em branco, e mascara cada linha com os
  /// nomes de [household].
  factory of(String text, {HouseholdNames household = HouseholdNames.empty}) {
    final original = [
      for (final line in text.split(_lineBreak))
        if (line.trim().isNotEmpty) line.trim(),
    ].take(StatementPageRequest.maxLines).toList();
    final masked = PiiRedactor.redactLines([
      for (final line in original) ReceiptText.clean(line),
    ], householdNames: household.names);
    return NumberedPage._(original, [for (final line in masked) _clip(line)]);
  }

  const new _(this.original, this.masked);

  /// Toda quebra de linha, inclusive o `\r` solto: linha com quebra dentro
  /// o servidor recusa, porque teria dois números.
  static final _lineBreak = RegExp(r'\r\n?|\n');

  /// As linhas como o OCR leu; a linha `n` está em `original[n - 1]`.
  final List<String> original;

  /// As mesmas linhas, mascaradas, como vão ao servidor.
  final List<String> masked;

  /// Linha mais longa que o contrato aceita perde o fim, que costuma ser
  /// ruído do OCR: recusar a página inteira por ela seria pior.
  static String _clip(String line) =>
      line.length <= StatementPageRequest.maxLineLength
      ? line
      : line.substring(0, StatementPageRequest.maxLineLength);
}
