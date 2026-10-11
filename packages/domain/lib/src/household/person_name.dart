import 'package:domain/src/notifications/notice_text.dart';
import 'package:meta/meta.dart';

/// O nome de uma pessoa reduzido ao que o banco não muda de um aviso para
/// outro: sem caixa, sem acento, sem pontuação e sem as partículas "de",
/// "da", "dos" (RN-1071).
///
/// Banco abrevia e corta nome: "Marcos Vinicius Muniz Arruda" chega como
/// "MARCOS V M ARRUDA" num aviso e "MARCOS VINICIUS MUNIZ A" no outro. A
/// comparação aceita isso, e só isso — um Marcos de outro sobrenome não é
/// a mesma pessoa, e transferir para ele é gasto.
@immutable
final class PersonName {
  const new _(this.words);

  /// Lê [raw] como nome de pessoa. Não usa a forma do estabelecimento
  /// (`PossibleDuplicate.normalize`): ela tira "sa" e "me" como razão
  /// social, e Sá é sobrenome.
  factory of(String raw) => PersonName._([
    for (final word in NoticeText.words(raw).split(' '))
      if (word.isNotEmpty && !_particles.contains(word)) word,
  ]);

  /// As palavras do nome, na ordem, já normalizadas.
  final List<String> words;

  /// Partículas que um banco escreve e outro tira.
  static const _particles = {'de', 'da', 'do', 'das', 'dos', 'e'};

  /// Se tem nome e sobrenome: só assim dá para conferir alguém (RN-1070).
  bool get isFull => words.length >= 2;

  /// Se [written], o nome como o banco escreveu, é esta pessoa (RN-1071).
  ///
  /// Casa quando: o primeiro nome vem inteiro; a última palavra é o último
  /// sobrenome — inteiro, só a inicial ou cortado no fim; as palavras do
  /// meio aparecem na ordem do cadastro, inteiras ou só a inicial, e
  /// alguma pode faltar; e há ao menos uma palavra além do primeiro nome
  /// escrita com mais de uma letra. "MARCOS A" não casa: é qualquer Marcos.
  bool isWrittenAs(PersonName written) {
    final read = written.words;
    if (!isFull || read.length < 2) return false;
    if (read.first != words.first) return false;
    if (!_fits(read.last, words.last, cut: true)) return false;
    if (!read.skip(1).any((word) => word.length > 1)) return false;
    return _inOrder(
      read.sublist(1, read.length - 1),
      words.sublist(1, words.length - 1),
    );
  }

  /// Se as duas formas podem ser a mesma pessoa, seja qual for a que veio
  /// do cadastro: o comprovante abrevia de um jeito e a notificação de
  /// outro (RN-1075).
  bool sameAs(PersonName other) =>
      isWrittenAs(other) || other.isWrittenAs(this);

  /// A palavra [read] é a palavra [full] escrita inteira ou só pela inicial;
  /// com [cut], também cortada no fim, que é onde o banco corta.
  static bool _fits(String read, String full, {bool cut = false}) =>
      read == full ||
      (read.length == 1 && full.startsWith(read)) ||
      (cut && full.startsWith(read));

  /// As palavras do meio lidas aparecem nas do cadastro, na mesma ordem. A
  /// primeira que serve é a certa: pular uma que serve nunca abre caminho
  /// para as seguintes.
  static bool _inOrder(List<String> read, List<String> full) {
    var at = 0;
    for (final word in read) {
      while (at < full.length && !_fits(word, full[at])) {
        at++;
      }
      if (at == full.length) return false;
      at++;
    }
    return true;
  }
}
