import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/http/payload_too_large.dart';
import 'package:shelf/shelf.dart';

/// Lê o corpo de uma requisição e o decodifica **sem deixar exceção sair**.
///
/// Antes, cada rota chamava o decodificador direto, e uma [FormatException]
/// subia até a última barreira (`Middlewares.errorBoundary`), que a traduzia
/// em `E-REQ-01`. Funcionava, mas dependia de ninguém esquecer que aquela
/// barreira existe. Aqui a recusa é um valor ([Refused]) que a rota trata num
/// `switch` exaustivo; a barreira continua lá, só como rede de segurança para
/// o que ninguém previu (ADR-015).
abstract final class RequestBody {
  /// Lê o corpo de [request], com teto de [limit] bytes, e o entrega a
  /// [read]. Corpo que não é JSON vira `E-REQ-01`; corpo grande demais vira
  /// `E-REQ-04`.
  static Future<Decoded<T>> decode<T>(
    Request request,
    T Function(Object? json) read, {
    int limit = JsonBody.maxBytes,
  }) async {
    final Object? json;
    try {
      json = await JsonBody.read(request, limit: limit);
    } on FormatException {
      return const Refused<Never>(ErrorCode.req01);
    } on PayloadTooLarge {
      return const Refused<Never>(ErrorCode.req04);
    }
    return Decoded.of(() => read(json));
  }

  /// Lê e decodifica o corpo, e então chama [next] com o que foi entendido.
  /// Se foi recusado, responde com o código do catálogo e [next] nem roda.
  static Future<Response> handle<T>(
    Request request,
    T Function(Object? json) read,
    FutureOr<Response> Function(T value) next, {
    int limit = JsonBody.maxBytes,
  }) async {
    return switch (await decode(request, read, limit: limit)) {
      Refused(:final code) => Responses.error(request, code),
      Understood(:final value) => await next(value),
    };
  }
}
