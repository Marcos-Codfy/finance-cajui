import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:shelf/shelf.dart';

/// Monta respostas HTTP — de sucesso e de erro — sempre em JSON com charset.
abstract final class Responses {
  static const _headers = {'content-type': 'application/json; charset=utf-8'};

  /// A chave em que o identificador da requisição viaja no contexto.
  static const refKey = 'cajui.ref';

  /// O identificador da requisição [request], para casar resposta e registro.
  static String refOf(Request request) => '${request.context[refKey] ?? ''}';

  /// Uma resposta de sucesso com [body] em JSON.
  static Response json(Object body, {int status = 200}) =>
      Response(status, body: jsonEncode(body), headers: _headers);

  /// A resposta de erro do catálogo: o corpo é sempre `ApiError`, e o status
  /// vem do próprio código. `Retry-After` acompanha [retryAfterSeconds].
  static Response error(
    Request request,
    ErrorCode code, {
    Map<String, Object?> detail = const {},
    int? retryAfterSeconds,
    int? status,
  }) {
    final error = ApiError(
      code: code,
      ref: refOf(request),
      detail: detail,
      retryAfterSeconds: retryAfterSeconds,
    );
    return Response(
      status ?? code.httpStatus ?? 500,
      body: jsonEncode(error.toJson()),
      headers: {
        ..._headers,
        if (retryAfterSeconds != null) 'retry-after': '$retryAfterSeconds',
      },
    );
  }
}
