/// A cadeia do registro está quebrada: uma linha foi alterada, removida,
/// reordenada ou não abre com a chave.
///
/// Carrega o ponto exato, porque "o banco corrompeu" não ajuda ninguém: o
/// texto do erro `E-DATA-01` diz a partir de qual evento o registro não
/// confere, e o servidor para de gravar para não piorar.
final class LogIntegrityException implements Exception {
  /// Cria a exceção para o registro [seq], com o motivo [reason].
  const new({required this.seq, required this.reason});

  /// A posição do primeiro registro que não confere.
  final int seq;

  /// O que não bateu, em uma frase.
  final String reason;

  @override
  String toString() => 'Registro $seq não confere: $reason';
}
