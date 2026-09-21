/// O registro não é o que foi gravado: alguém alterou o conteúdo, a ordem ou
/// os dados associados — ou a chave é outra.
///
/// É exceção, e não falha de domínio, porque não é uma regra de negócio
/// recusando um pedido: é o estado do disco contrariando o que o programa
/// escreveu. Na borda do servidor ela vira `E-DATA-01`.
final class RecordTamperedException implements Exception {
  /// Cria a exceção.
  const new();

  @override
  String toString() => 'Registro adulterado, ou chave errada.';
}
