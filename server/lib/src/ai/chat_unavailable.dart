/// O serviço de IA não respondeu como devia: fora do ar, lento, limitando
/// requisições. Quem chama cai nas regras locais — a IA nunca é
/// pré-requisito.
final class ChatUnavailable implements Exception {
  /// Cria a exceção. [retryAfterSeconds] vem do serviço, quando ele limita.
  const new({this.retryAfterSeconds, this.status});

  /// Em quantos segundos o serviço pediu para tentar de novo.
  final int? retryAfterSeconds;

  /// O código HTTP da resposta, quando houve resposta.
  final int? status;

  /// Se o serviço **recusou o pedido** (4xx, fora o 429): o serviço está no
  /// ar, e o que ele não aceitou foi este pedido — uma imagem, um formato.
  /// Não é sinal de queda.
  bool get rejected {
    final code = status;
    return code != null && code >= 400 && code < 500 && code != 429;
  }
}
