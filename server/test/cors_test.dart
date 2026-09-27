import 'package:server/src/app.dart';
import 'package:server/src/http/rate_limiter.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

void main() {
  late TestApp server;

  setUp(() async {
    server = await TestApp.start();
  });

  group('a web de consulta fala com o servidor de outra origem', () {
    test(
      'a pergunta prévia do navegador é respondida para a origem da web',
      () async {
        final response = await server.send(
          'OPTIONS',
          '/v1/plan',
          headers: {
            'origin': App.defaultWebOrigin,
            'access-control-request-method': 'GET',
          },
        );

        expect(response.statusCode, 204);
        expect(
          response.headers['access-control-allow-origin'],
          App.defaultWebOrigin,
        );
        expect(
          response.headers['access-control-allow-methods'],
          contains('GET'),
        );
        expect(
          response.headers['access-control-allow-headers'],
          contains('authorization'),
        );
      },
    );

    test('a resposta de verdade leva o cabeçalho, inclusive a recusa: a web '
        'precisa ler o código do erro', () async {
      final ok = await server.send(
        'GET',
        '/health',
        headers: {'origin': App.defaultWebOrigin},
      );
      final refused = await server.send(
        'GET',
        '/v1/plan',
        headers: {'origin': App.defaultWebOrigin},
      );

      expect(ok.headers['access-control-allow-origin'], App.defaultWebOrigin);
      expect(ok.headers['vary'], 'origin');
      expect(refused.statusCode, 401);
      expect(
        refused.headers['access-control-allow-origin'],
        App.defaultWebOrigin,
      );
    });

    test('outra origem não recebe cabeçalho nenhum', () async {
      final preflight = await server.send(
        'OPTIONS',
        '/v1/plan',
        headers: {
          'origin': 'https://outro-site.example',
          'access-control-request-method': 'GET',
        },
      );
      final plain = await server.send(
        'GET',
        '/health',
        headers: {'origin': 'https://outro-site.example'},
      );

      expect(preflight.statusCode, isNot(204));
      expect(
        preflight.headers.containsKey('access-control-allow-origin'),
        isFalse,
      );
      expect(plain.headers.containsKey('access-control-allow-origin'), isFalse);
    });

    test('a recusa por limite e a por pedido malformado também levam o '
        'cabeçalho: sem ele a web veria "sem servidor"', () async {
      final tight = await TestApp.start(
        rateLimiter: RateLimiter(perOrigin: 1, global: 10),
      );
      final origin = {'origin': App.defaultWebOrigin};
      await tight.send('GET', '/health', headers: origin);
      final limited = await tight.send('GET', '/health', headers: origin);
      final malformed = await server.send(
        'POST',
        '/v1/auth/web',
        headers: {...origin, 'content-type': 'application/json'},
        body: {'code': 123},
      );

      expect(limited.statusCode, 429);
      expect(
        limited.headers['access-control-allow-origin'],
        App.defaultWebOrigin,
      );
      expect(malformed.statusCode, 400);
      expect(
        malformed.headers['access-control-allow-origin'],
        App.defaultWebOrigin,
      );
    });

    test('o app Android, que não manda origem, passa como sempre', () async {
      final response = await server.send('GET', '/health');

      expect(response.statusCode, 200);
      expect(
        response.headers.containsKey('access-control-allow-origin'),
        isFalse,
      );
    });
  });
}
