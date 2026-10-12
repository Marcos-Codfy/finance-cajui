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

  /// O id com que a linha de chave [base] é gravada.
  ///
  /// A primeira tentativa é a própria chave. Se ela já está no livro e
  /// ativa, a linha já está lá (`alreadyThere`): ler de novo não lança. Se
  /// está no livro mas foi desfeita, passa para a próxima tentativa — e
  /// lançar de novo depois de desfazer grava, em vez de ser ignorado.
  static ({String id, bool alreadyThere}) idFor(
    String base, {
    required bool Function(String id) isKnown,
    required bool Function(String id) isActive,
  }) {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final id = attempt == 0 ? base : '$base-r$attempt';
      if (!isKnown(id)) return (id: id, alreadyThere: false);
      if (isActive(id)) return (id: id, alreadyThere: true);
    }
    return (id: '$base-r$_maxAttempts', alreadyThere: false);
  }

  /// Desfazer e lançar a mesma linha cinquenta vezes não é uso de verdade;
  /// o teto só garante que o laço termina.
  static const _maxAttempts = 50;

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
