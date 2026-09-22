import 'dart:convert';

import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/rate_limiter.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';
import 'support/test_device.dart';

void main() {
  late TestApp server;
  late String token;

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
    await server.call(
      'POST',
      '/v1/categories',
      body: groceriesBody,
      token: token,
    );
  });

  group('autenticação', () {
    test('ADR-008 cadastro, desafio e assinatura abrem uma sessão', () async {
      final device = TestDevice.generate();
      final code = EnrollmentCodes(server.data).issue();

      final (enrolled, _) = await server.call(
        'POST',
        '/v1/auth/enroll',
        body: {
          'code': code,
          'deviceId': 'pixel',
          'name': 'Pixel do Marcos',
          'publicKey': base64Encode(device.publicKeyX509),
        },
      );
      final (_, challenge) = await server.call(
        'POST',
        '/v1/auth/challenge',
        body: {'deviceId': 'pixel'},
      );
      final nonce = base64Decode(challenge['nonce']! as String);
      final (status, session) = await server.call(
        'POST',
        '/v1/auth/session',
        body: {
          'challengeId': challenge['challengeId'],
          'signature': base64Encode(device.sign(nonce)),
        },
      );
      final (authorized, _) = await server.call(
        'GET',
        '/v1/head',
        token: session['token']! as String,
      );

      expect((enrolled, status, authorized), (201, 200, 200));
    });

    test(
      'T-03 código de cadastro errado, ou usado de novo, vira E-AUTH-04',
      () async {
        final device = TestDevice.generate();
        final code = EnrollmentCodes(server.data).issue();
        Future<(int, Map<String, Object?>)> enroll(String withCode) =>
            server.call(
              'POST',
              '/v1/auth/enroll',
              body: {
                'code': withCode,
                'deviceId': 'pixel',
                'name': 'Pixel',
                'publicKey': base64Encode(device.publicKeyX509),
              },
            );

        final wrong = await enroll('AAAAAAAAAA');
        final right = await enroll(code);
        final reused = await enroll(code);

        expect(errorOf(wrong.$2)['code'], 'E-AUTH-04');
        expect(right.$1, 201);
        expect(errorOf(reused.$2)['code'], 'E-AUTH-04');
      },
    );

    test(
      'T-02 e T-04 assinatura de outra chave, ou desafio reusado, não entra',
      () async {
        final device = TestDevice.generate();
        await server.call(
          'POST',
          '/v1/auth/enroll',
          body: {
            'code': EnrollmentCodes(server.data).issue(),
            'deviceId': 'pixel',
            'name': 'Pixel',
            'publicKey': base64Encode(device.publicKeyX509),
          },
        );
        final (_, challenge) = await server.call(
          'POST',
          '/v1/auth/challenge',
          body: {'deviceId': 'pixel'},
        );
        final nonce = base64Decode(challenge['nonce']! as String);
        Future<(int, Map<String, Object?>)> open(List<int> signature) =>
            server.call(
              'POST',
              '/v1/auth/session',
              body: {
                'challengeId': challenge['challengeId'],
                'signature': base64Encode(signature),
              },
            );

        final forged = await open(device.sign([...nonce]..[0] ^= 1));
        final replayed = await open(device.sign(nonce));

        expect((forged.$1, errorOf(forged.$2)['code']), (401, 'E-AUTH-03'));
        // O desafio foi consumido pela primeira tentativa: a assinatura certa,
        // agora, já não serve.
        expect((replayed.$1, errorOf(replayed.$2)['code']), (401, 'E-AUTH-03'));
      },
    );

    test(
      'RNF-SEC-18 sem token, com token inválido: a mesma resposta vaga',
      () async {
        final none = await server.call('GET', '/v1/head');
        final bad = await server.call('GET', '/v1/head', token: 'inventado');

        expect(none.$1, 401);
        expect(errorOf(none.$2)['code'], 'E-AUTH-03');
        expect(errorOf(bad.$2)['code'], errorOf(none.$2)['code']);
        expect(errorOf(bad.$2)['detail'], isEmpty);
      },
    );

    test(
      'T-12 sessão da web lê, mas não escreve — imposto no servidor',
      () async {
        final web = server.token(scope: SessionScope.webReadOnly);

        final read = await server.call('GET', '/v1/entries', token: web);
        final write = await server.call(
          'POST',
          '/v1/entries',
          body: entryBody(),
          token: web,
        );

        expect(read.$1, 200);
        expect((write.$1, errorOf(write.$2)['code']), (403, 'E-AUTH-03'));
      },
    );
  });

  group('limite de taxa e registro', () {
    test(
      'T-11 acima do limite vira E-RATE-01, com o tempo de espera',
      () async {
        final limited = await TestApp.start(
          rateLimiter: RateLimiter(perOrigin: 2, global: 100),
        );
        final session = limited.token();
        await limited.call('GET', '/v1/head', token: session);
        await limited.call('GET', '/v1/head', token: session);

        final (status, body) = await limited.call(
          'GET',
          '/v1/head',
          token: session,
        );

        expect((status, errorOf(body)['code']), (429, 'E-RATE-01'));
        expect(errorOf(body)['retryAfterSeconds'], isPositive);
      },
    );

    test('T-09 o registro não guarda valor, descrição nem corpo', () async {
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);
      await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(id: 'e2', cents: -1),
        token: token,
      );

      final logged = server.logs.join('\n');

      expect(server.logs, isNotEmpty);
      expect(logged, isNot(contains('Mercado')));
      expect(logged, isNot(contains('8600')));
      expect(logged, isNot(contains(token)));
      expect(logged, contains('"path":"/v1/entries"'));
    });

    test('todo erro carrega o ref que também está no registro', () async {
      final (_, body) = await server.call('GET', '/v1/head');

      final ref = errorOf(body)['ref']! as String;

      expect(ref, hasLength(6));
      expect(server.logs.last, contains('"ref":"$ref"'));
    });
  });

  group('estou de pé', () {
    test('o /health responde sem token, e não conta nada da casa', () async {
      final (status, body) = await server.call('GET', '/health');

      expect(status, 200);
      expect(body, {'status': 'ok'});
    });

    test('token errado no /health não muda nada: ele é público', () async {
      final (status, _) = await server.call('GET', '/health', token: 'nao-vale');

      expect(status, 200);
    });
  });
}
