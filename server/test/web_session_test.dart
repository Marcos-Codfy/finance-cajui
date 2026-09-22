import 'package:test/test.dart';

import 'support/test_app.dart';

/// A consulta no navegador (ADR-013).
///
/// O navegador não ganha chave nem identidade: quem responde por ele é o
/// celular, que emite um código curto. O que a web recebe é um token **só de
/// leitura**, e o escopo é decidido aqui, no servidor.
void main() {
  late TestApp server;
  late String token;

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
  });

  Future<String> codigo() async {
    final (_, body) = await server.call(
      'POST',
      '/v1/devices/web-codes',
      body: const {},
      token: token,
    );
    return body['code']! as String;
  }

  test('o código do celular vira sessão de leitura no navegador', () async {
    final code = await codigo();

    final (status, body) = await server.call(
      'POST',
      '/v1/auth/web',
      body: {'code': code},
    );

    expect(status, 200);
    expect(body['token'], isA<String>());
    // Duas horas: o navegador não tem como se renovar sozinho.
    expect(body['expiresInSeconds'], 7200);
  });

  test('o código vale uma vez só', () async {
    final code = await codigo();
    await server.call('POST', '/v1/auth/web', body: {'code': code});

    final (status, _) = await server.call(
      'POST',
      '/v1/auth/web',
      body: {'code': code},
    );

    expect(status, 401);
  });

  test('código inventado não abre nada', () async {
    final (status, _) = await server.call(
      'POST',
      '/v1/auth/web',
      body: const {'code': 'NAOEXISTE'},
    );

    expect(status, 401);
  });

  test('RN-906 · a sessão da web lê, e não escreve', () async {
    final code = await codigo();
    final (_, opened) = await server.call(
      'POST',
      '/v1/auth/web',
      body: {'code': code},
    );
    final web = opened['token']! as String;

    final (lendo, _) = await server.call('GET', '/v1/entries', token: web);
    final (escrevendo, _) = await server.call(
      'POST',
      '/v1/categories',
      body: const {
        'id': 'x',
        'name': 'X',
        'block': 'variable',
        'groupId': 'g',
        'voucherEligible': false,
      },
      token: web,
    );

    expect(lendo, 200);
    expect(escrevendo, 403, reason: 'quem só lê não grava');
  });

  test('T-12 · a web não convida a web', () async {
    final code = await codigo();
    final (_, opened) = await server.call(
      'POST',
      '/v1/auth/web',
      body: {'code': code},
    );

    final (status, _) = await server.call(
      'POST',
      '/v1/devices/web-codes',
      body: const {},
      token: opened['token']! as String,
    );

    expect(status, 403);
  });
}
