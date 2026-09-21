/// O corpo da requisição passou do tamanho que a API aceita. Na borda vira
/// `E-REQ-04`.
final class PayloadTooLarge implements Exception {
  /// Cria a exceção.
  const new();
}
