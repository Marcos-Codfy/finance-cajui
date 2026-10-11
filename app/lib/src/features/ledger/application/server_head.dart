import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O topo do registro no servidor: a pergunta mais barata que dá para
/// fazer a ele (ADR-024).
///
/// Responde um número — o `seq` do último fato que mexeu no livro —, e é
/// por ele que o aparelho sabe, a cada 20 segundos, se o outro celular
/// lançou alguma coisa. Só quando o número anda vale descer o livro.
abstract interface class ServerHead {
  /// O `ledgerSeq` do servidor agora; `null` quando não deu para perguntar
  /// — sem rede, sem chave, servidor fora do ar. Nulo não é zero: um
  /// servidor que não respondeu não é um servidor que não mudou.
  Future<int?> ledgerSeq();
}

/// O topo do servidor. A raiz do app decide qual.
final serverHeadProvider = Provider<ServerHead>(
  (ref) => throw StateError('serverHeadProvider sem override na raiz.'),
);
