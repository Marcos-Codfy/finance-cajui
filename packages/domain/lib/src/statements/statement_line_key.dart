import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';

/// A chave de uma linha de extrato gravada (RN-1117, RN-1119).
///
/// Antes, a chave era a posição da linha no que a IA devolveu: ler o mesmo
/// extrato de novo, ou recebê-lo noutra ordem, lançava em dobro. Agora ela
/// vem do conteúdo — dia, valor, estabelecimento — e do número de ordem
/// entre linhas iguais: duas compras de R$ 8,00 na mesma padaria no mesmo
/// dia são a 1 e a 2, e continuam sendo a 1 e a 2 na próxima leitura.
abstract final class StatementLineKey {
  /// As chaves de [lines], na ordem em que vieram.
  static List<String> of(
    List<({LocalDate on, Money amount, String merchantKey})> lines,
  ) {
    final seen = <String, int>{};
    return [
      for (final line in lines)
        () {
          final content =
              '${line.on}-${line.amount.cents}-${_hash(line.merchantKey)}';
          final ordinal = seen[content] = (seen[content] ?? 0) + 1;
          return 'st-$content-$ordinal';
        }(),
    ];
  }

  /// O id com que a linha de chave [base] é gravada na leitura [launch].
  ///
  /// A linha já está lá (`alreadyThere`) quando algum lançamento ativo tem
  /// a mesma chave — gravado por esta leitura ou por outra, neste celular ou
  /// no outro: ler de novo não lança em dobro. Senão, o id é a chave mais o
  /// carimbo da leitura. Assim, lançar de novo depois de desfazer grava com
  /// um id que nunca foi desfeito em lugar nenhum — o celular que ainda não
  /// soube do desfazer feito no outro não grava um id já cancelado, que o
  /// servidor apagaria em silêncio (RN-1119).
  static ({String id, bool alreadyThere}) idFor(
    String base, {
    required String launch,
    required Iterable<String> activeIds,
  }) {
    final there = activeIds.any((id) => id == base || id.startsWith('$base~'));
    return (id: there ? base : '$base~$launch', alreadyThere: there);
  }

  /// FNV-1a de 32 bits, em hexadecimal: curto, estável entre versões do
  /// Dart (ao contrário de `hashCode`) e sem o nome do lugar no id. A
  /// multiplicação pelo primo 16777619 vai em deslocamentos: na web o
  /// produto de dois números de 32 bits perderia precisão, e a mesma linha
  /// ganharia outra chave.
  static String _hash(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash =
          (hash +
              (hash << 1) +
              (hash << 4) +
              (hash << 7) +
              (hash << 8) +
              (hash << 24)) &
          0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
