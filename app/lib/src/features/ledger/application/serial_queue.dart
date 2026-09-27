/// Um trabalho de cada vez, na ordem em que chegaram.
///
/// Gravar um fato e aplicá-lo ao livro são dois passos com um `await` no
/// meio. Dois fatos entrelaçados — um lançamento daqui e uma descida do
/// outro aparelho, por exemplo — aplicariam cada um sobre um livro que já
/// não é o último, e um apagaria o outro da tela até o app reabrir (BL-062).
/// A fila garante que o segundo só começa quando o primeiro terminou.
final class SerialQueue {
  Future<void> _tail = Future.value();

  /// Executa [work] depois de tudo o que já estava na fila. Uma falha em
  /// [work] chega a quem chamou, e não trava os que vêm depois.
  Future<T> run<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then((_) {}, onError: (Object _) {});
    return result;
  }
}
