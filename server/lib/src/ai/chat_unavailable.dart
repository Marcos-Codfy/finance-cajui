/// O serviço de IA não respondeu como devia: fora do ar, lento, limitando
/// requisições. Quem chama cai nas regras locais — a IA nunca é
/// pré-requisito.
final class ChatUnavailable implements Exception {
  /// Cria a exceção. [retryAfterSeconds] vem do serviço, quando ele limita.
  const new({this.retryAfterSeconds});

  /// Em quantos segundos o serviço pediu para tentar de novo.
  final int? retryAfterSeconds;
}
