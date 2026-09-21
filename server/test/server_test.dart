import 'dart:convert';

import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/rate_limiter.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';
import 'support/test_device.dart';

const Map<String, Object?> _groceries = {
  'id': 'groceries',
  'name': 'Mercado',
  'block': 'variable',
  'groupId': 'food',
  'voucherEligible': true,
};

Map<String, Object?> _entry({
  String id = 'e1',
  int cents = 8600,
  String on = '2026-09-12',
  List<Map<String, Object?>>? lines,
}) => {
  'id': id,
  'description': 'Mercado Boa Compra',
  'amountCents': cents,
  'occurredOn': on,
  'categoryId': 'groceries',
  'paymentLines':
      lines ??
      [
        {'paymentMethodId': 'voucher', 'kind': 'mealVoucher', 'amountCents': 3000},
        {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 5600},
      ],
};

Map<String, Object?> _error(Map<String, Object?> body) =>
    body['error']! as Map<String, Object?>;

void main() {
  late TestApp server;
  late String token;

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
    await server.call('POST', '/v1/categories', body: _groceries, token: token);
  });

  group('lançamentos', () {
    test('cria, grava o evento e lista pelo mês', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: _entry(),
        token: token,
      );
      final (_, listed) = await server.call(
        'GET',
        '/v1/entries?month=2026-09',
        token: token,
      );

      expect(status, 201);
      expect(body['seq'], 2);
      expect(listed['entries'], hasLength(1));
      expect(server.store.events.last.type, 'entry.created');
    });

    test('T-05 o servidor revalida as regras: soma errada vira E-ENTRY-01',
        () async {
      final lines = [
        {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 5000},
      ];

      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: _entry(lines: lines),
        token: token,
      );

      expect(status, 422);
      expect(_error(body)['code'], 'E-ENTRY-01');
      expect(_error(body)['class'], 'regra');
      expect(_error(body)['detail'], {
        'amountCents': 8600,
        'linesTotalCents': 5000,
      });
      expect(server.store.events, hasLength(1));
    });

    test('RN-206 data no futuro vira E-ENTRY-02', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: _entry(on: '2026-09-21'),
        token: token,
      );

      expect((status, _error(body)['code']), (422, 'E-ENTRY-02'));
    });

    test('ADR-012 o mesmo comando duas vezes vira um lançamento só', () async {
      final first = await server.call(
        'POST',
        '/v1/entries',
        body: _entry(),
        token: token,
      );
      final again = await server.call(
        'POST',
        '/v1/entries',
        body: _entry(),
        token: token,
      );

      expect(again.$1, 201);
      expect(again.$2['seq'], first.$2['seq']);
      expect(server.store.events, hasLength(2));
    });

    test('RNF-SEC-09 pedido malformado vira E-REQ-01, nunca erro interno',
        () async {
      final bodies = [
        {..._entry(), 'isAdmin': true},
        _entry(on: '2026-02-30'),
        _entry(
          lines: [
            {'paymentMethodId': 'x', 'kind': 'bitcoin', 'amountCents': 8600},
          ],
        ),
      ];

      for (final body in bodies) {
        final (status, json) = await server.call(
          'POST',
          '/v1/entries',
          body: body,
          token: token,
        );
        expect((status, _error(json)['code']), (400, 'E-REQ-01'));
      }
    });

    test('categoria que não existe vira E-REQ-02', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: {..._entry(), 'categoryId': 'sumiu'},
        token: token,
      );

      expect((status, _error(body)['code']), (404, 'E-REQ-02'));
    });

    test('T-25 corpo acima do teto vira E-REQ-04', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: {..._entry(), 'description': 'x' * 70000},
        token: token,
      );

      expect((status, _error(body)['code']), (413, 'E-REQ-04'));
    });
  });

  group('categorias', () {
    test('RN-207 nome que representa cartão vira E-CARD-02', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/categories',
        body: {..._groceries, 'id': 'card', 'name': 'Cartão Nubank'},
        token: token,
      );

      expect((status, _error(body)['code']), (422, 'E-CARD-02'));
    });
  });

  group('estado reconstruído', () {
    test('ADR-004 reabrir o registro devolve o mesmo estado', () async {
      await server.call('POST', '/v1/entries', body: _entry(), token: token);
      final (_, head) = await server.call('GET', '/v1/head', token: token);

      expect(head['seq'], 2);
    });
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

    test('T-03 código de cadastro errado, ou usado de novo, vira E-AUTH-04',
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

      expect(_error(wrong.$2)['code'], 'E-AUTH-04');
      expect(right.$1, 201);
      expect(_error(reused.$2)['code'], 'E-AUTH-04');
    });

    test('T-02 e T-04 assinatura de outra chave, ou desafio reusado, não entra',
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

      expect((forged.$1, _error(forged.$2)['code']), (401, 'E-AUTH-03'));
      // O desafio foi consumido pela primeira tentativa: a assinatura certa,
      // agora, já não serve.
      expect((replayed.$1, _error(replayed.$2)['code']), (401, 'E-AUTH-03'));
    });

    test('RNF-SEC-18 sem token, com token inválido: a mesma resposta vaga',
        () async {
      final none = await server.call('GET', '/v1/head');
      final bad = await server.call('GET', '/v1/head', token: 'inventado');

      expect(none.$1, 401);
      expect(_error(none.$2)['code'], 'E-AUTH-03');
      expect(_error(bad.$2)['code'], _error(none.$2)['code']);
      expect(_error(bad.$2)['detail'], isEmpty);
    });

    test('T-12 sessão da web lê, mas não escreve — imposto no servidor',
        () async {
      final web = server.token(scope: SessionScope.webReadOnly);

      final read = await server.call('GET', '/v1/entries', token: web);
      final write = await server.call(
        'POST',
        '/v1/entries',
        body: _entry(),
        token: web,
      );

      expect(read.$1, 200);
      expect((write.$1, _error(write.$2)['code']), (403, 'E-AUTH-03'));
    });
  });

  group('limite de taxa e registro', () {
    test('T-11 acima do limite vira E-RATE-01, com o tempo de espera',
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

      expect((status, _error(body)['code']), (429, 'E-RATE-01'));
      expect(_error(body)['retryAfterSeconds'], isPositive);
    });

    test('T-09 o registro não guarda valor, descrição nem corpo', () async {
      await server.call('POST', '/v1/entries', body: _entry(), token: token);
      await server.call(
        'POST',
        '/v1/entries',
        body: _entry(id: 'e2', cents: -1),
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

      final ref = _error(body)['ref']! as String;

      expect(ref, hasLength(6));
      expect(server.logs.last, contains('"ref":"$ref"'));
    });
  });
}
