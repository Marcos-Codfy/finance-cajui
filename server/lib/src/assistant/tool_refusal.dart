/// Uma ferramenta que não pôde atender o pedido do modelo: argumento que
/// falta, categoria que não existe, regra do domínio que recusou.
///
/// Não é erro do servidor: volta ao modelo como resultado, em texto, para
/// ele corrigir o pedido ou explicar à pessoa o que faltou.
final class ToolRefusal implements Exception {
  /// Cria a recusa com o motivo, nas palavras que o modelo lê.
  const new(this.message);

  /// O motivo.
  final String message;

  @override
  String toString() => 'ToolRefusal($message)';
}
