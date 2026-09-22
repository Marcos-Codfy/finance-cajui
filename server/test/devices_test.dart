import 'dart:convert';

import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';
import 'support/test_device.dart';

/// Quem tem acesso a esta casa — e como um aparelho novo entra sem ninguém
/// abrir o servidor por fora.
void main() {
  late TestApp server;
  late String token;

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
  });

  group('os aparelhos com acesso', () {
    /// Cadastra um aparelho de verdade: a lista só mostra quem passou pelo
    /// cadastro, e não quem o teste abriu sessão à força.
    Future<void> enroll(String id, String name) async {
      final device = TestDevice.generate();
      await server.call(
        'POST',
        '/v1/auth/enroll',
        body: {
          'code': EnrollmentCodes(server.data).issue(),
          'deviceId': id,
          'name': name,
          'publicKey': base64Encode(device.publicKeyX509),
        },
      );
    }

    test(
      'o celular cadastrado convida outro, sem abrir o servidor por fora',
      () async {
        final (status, body) = await server.call(
          'POST',
          '/v1/devices/codes',
          body: const {},
          token: token,
        );

        expect(status, 200);
        expect(body['code'], isA<String>());
        expect(body['expiresInSeconds'], 600);
      },
    );

    test('a lista mostra quem tem acesso, e nenhuma chave', () async {
      await enroll('s22', 'Meu S22');

      final (status, body) = await server.call(
        'GET',
        '/v1/devices',
        token: token,
      );

      expect(status, 200);
      final devices = (body['devices']! as List).cast<Map<String, Object?>>();
      expect(devices.single.keys.toSet(), {'id', 'name', 'kind'});
      expect(devices.single['kind'], 'device');
    });

    test('revogar tira o aparelho, e a sessão dele morre junto', () async {
      await enroll('velho', 'Celular antigo');
      final velho = server.app.sessions.open(
        'velho',
        scope: SessionScope.device,
      );

      final (status, _) = await server.call(
        'DELETE',
        '/v1/devices/velho',
        token: token,
      );

      expect(status, 200);
      final (_, listed) = await server.call('GET', '/v1/devices', token: token);
      expect(listed['devices'], isEmpty);
      // Revogar que só vale no próximo login não é revogar.
      final (depois, _) = await server.call('GET', '/v1/devices', token: velho);
      expect(depois, 401);
    });
  });
}
