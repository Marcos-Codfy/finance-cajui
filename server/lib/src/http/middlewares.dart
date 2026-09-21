import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:api_contract/api_contract.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/payload_too_large.dart';
import 'package:server/src/http/rate_limiter.dart';
import 'package:shelf/shelf.dart';

/// Os middlewares comuns a toda rota, na ordem em que entram no `Pipeline`.
abstract final class Middlewares {
  static final _random = Random.secure();

  /// Dá a cada requisição um identificador curto (`ref`), devolvido no corpo
  /// de erro e gravado no registro: é o que liga "o erro que eu vi" a "o que
  /// aconteceu no servidor", sem registrar dado nenhum da pessoa.
  static Middleware requestRef() => (inner) => (request) async {
    final ref = [
      for (var i = 0; i < 3; i++)
        _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    final response = await inner(
      request.change(context: {Responses.refKey: ref}),
    );
    return response.change(headers: {'x-request-ref': ref});
  };

  /// Registra cada requisição em uma linha JSON: instante, `ref`, método,
  /// caminho **sem a query**, status e duração.
  ///
  /// Nunca o corpo, nunca um valor, nunca uma descrição (RNF-SEC-12 · T-09).
  /// O que aconteceu com o dinheiro de alguém não é assunto de log.
  static Middleware accessLog(void Function(String line) sink) =>
      (inner) => (request) async {
        final watch = Stopwatch()..start();
        final response = await inner(request);
        sink(
          jsonEncode({
            'at': DateTime.now().toUtc().toIso8601String(),
            'ref': Responses.refOf(request),
            'method': request.method,
            'path': '/${request.url.path}',
            'status': response.statusCode,
            'ms': watch.elapsedMilliseconds,
          }),
        );
        return response;
      };

  /// Recusa com `E-RATE-01` o que passar do limite, dizendo em quantos
  /// segundos dá para tentar de novo.
  static Middleware rateLimit(RateLimiter limiter) => (inner) => (request) {
    final wait = limiter.retryAfterSeconds(_originOf(request));
    if (wait == null) return inner(request);
    return Responses.error(
      request,
      ErrorCode.rate01,
      detail: {'seconds': wait},
      retryAfterSeconds: wait,
    );
  };

  /// A origem da requisição. `X-Forwarded-For` só vale quando quem conecta é
  /// a própria máquina — o Caddy. Vindo de fora, o cabeçalho é ignorado: o
  /// cliente não escolhe o próprio endereço (ASVS 4.1.3).
  static String _originOf(Request request) {
    final info = request.context['shelf.io.connection_info'];
    if (info is! HttpConnectionInfo) return 'local';
    final forwarded = request.headers['x-forwarded-for'];
    if (info.remoteAddress.isLoopback && forwarded != null) {
      return forwarded.split(',').first.trim();
    }
    return info.remoteAddress.address;
  }

  /// A última barreira: nenhuma exceção chega ao cliente como pilha de
  /// execução ou como texto livre. Cada uma vira um código do catálogo, e o
  /// registro guarda só o **tipo** da exceção, com o `ref`.
  static Middleware errorBoundary(void Function(String line) sink) =>
      (inner) => (request) async {
        try {
          return await inner(request);
        } on FormatException {
          return Responses.error(request, ErrorCode.req01);
        } on PayloadTooLarge {
          return Responses.error(request, ErrorCode.req04);
        } on LogIntegrityException catch (error) {
          _note(sink, request, error);
          return Responses.error(
            request,
            ErrorCode.data01,
            detail: {'seq': error.seq},
          );
        } on Object catch (error) {
          _note(sink, request, error);
          return Responses.error(request, ErrorCode.srv01);
        }
      };

  static void _note(void Function(String) sink, Request request, Object error) {
    sink(
      jsonEncode({
        'at': DateTime.now().toUtc().toIso8601String(),
        'ref': Responses.refOf(request),
        'exception': '${error.runtimeType}',
      }),
    );
  }
}
