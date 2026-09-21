import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// Servidor mínimo do spike B.
///
/// Tem o bastante para a medição valer: roteador, middleware, JSON de
/// entrada e de saída, e o formato de erro do catálogo. Não tem nada do
/// produto — o que se mede é a cadeia de compilação, não o Cajui.
Future<void> main() async {
  final router = Router()
    ..get('/v1/health', _health)
    ..post('/v1/echo', _echo);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Só escuta fora da própria máquina se mandarem: em produção quem recebe a
  // internet é o proxy reverso, e o servidor fica no endereço local.
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress(host), port);
  stdout.writeln('ouvindo em http://${server.address.host}:${server.port}');
}

Response _health(Request request) => _json(200, {
  'status': 'ok',
  'os': Platform.operatingSystem,
  'dart': Platform.version.split(' ').first,
});

Future<Response> _echo(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    return _json(200, {'received': body});
  } on FormatException {
    return _json(400, {
      'error': {'code': 'E-REQ-01', 'class': 'servidor', 'ref': 'spike'},
    });
  }
}

Response _json(int status, Object body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);
