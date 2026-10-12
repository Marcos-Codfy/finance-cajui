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
  /// Numera [text], sem as linhas em branco e com os números que o OCR
  /// quebrou consertados (`OcrLine`), e mascara cada linha com os nomes de
  /// [household].
  factory of(String text, {HouseholdNames household = HouseholdNames.empty}) {
    final original = [
      for (final line in text.split(_lineBreak))
        if (line.trim().isNotEmpty) OcrLine.tidy(line.trim()),
    ].take(StatementPageRequest.maxLines).toList();
    final masked = PiiRedactor.redactLines([
      for (final line in original) ReceiptText.clean(line),
    ], householdNames: household.names);
    final people = TransferLine.peopleIn(original);
    return NumberedPage._(
      original,
      [for (final line in masked) _clip(line)],
      people: {
        for (final MapEntry(:key, :value) in people.entries) key + 1: value,
      },
    );
  }

  const new _(this.original, this.masked, {required this.people});

  /// Toda quebra de linha, inclusive o `\r` solto: linha com quebra dentro
  /// o servidor recusa, porque teria dois números.
  static final _lineBreak = RegExp(r'\r\n?|\n');

  /// As linhas como o OCR leu; a linha `n` está em `original[n - 1]`.
  final List<String> original;

  /// As mesmas linhas, mascaradas, como vão ao servidor.
  final List<String> masked;

  /// Os nomes de pessoa das linhas originais, pelo número da linha, como
  /// estão escritos (RN-1106). São os mesmos que a máscara trocou por
  /// `[NOME]` — inclusive o que o banco põe na linha de baixo de
  /// "Transferência enviada pelo Pix", que fica no número dessa linha.
  final Map<int, String> people;

  /// O nome de quem recebeu ou mandou o dinheiro na movimentação que a IA
  /// citou na linha [line]: o da própria linha, ou o da linha de baixo
  /// quando ela é só o nome que o banco quebrou. Sem esse cuidado, o Pix
  /// do formato em duas linhas chegava à pergunta sem a pessoa.
  String? personOn(int line) {
    if (people[line] case final name?) return name;
    // O nome de baixo é desta linha quando a de baixo não tem marcador
    // próprio: foi daqui que a busca o achou.
    final below = line < original.length ? original[line] : null;
    if (below == null || TransferLine.personIn(below) != null) return null;
    return people[line + 1];
  }

  /// Linha mais longa que o contrato aceita perde o fim, que costuma ser
  /// ruído do OCR: recusar a página inteira por ela seria pior.
  static String _clip(String line) =>
      line.length <= StatementPageRequest.maxLineLength
      ? line
      : line.substring(0, StatementPageRequest.maxLineLength);
}
