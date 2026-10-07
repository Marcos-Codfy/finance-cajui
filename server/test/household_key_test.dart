import 'dart:io';

import 'package:server/src/auth/household_key.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

/// Uma chave como a que o PC do dono gera: 43 caracteres de base64url.
const _key = 'Qm9hIG5vaXRlLCBNYXJjb3M6IGRvcm1lIGJlbQ-xyz_';

/// Outra chave, do mesmo tamanho, que não é a da casa.
const _wrongKey = 'outra-chave-qualquer-de-tamanho-parecido';

void main() {
  group('ADR-020 · a chave da casa', () {
    test(
      'entra em qualquer rota, lê e escreve, sem cadastro nem desafio',
      () async {
        final server = await TestApp.start(householdKey: HouseholdKey(_key));

        final (created, _) = await server.call(
          'POST',
          '/v1/categories',
          body: groceriesBody,
          token: _key,
        );
        final (written, _) = await server.call(
          'POST',
          '/v1/entries',
          body: entryBody(),
          token: _key,
        );
        final (read, body) = await server.call(
          'GET',
          '/v1/entries',
          token: _key,
        );

        expect(created, 201);
        expect(written, 201);
        expect(read, 200);
        expect(body['entries'], hasLength(1));
      },
    );

    test(
      'chave errada, chave parecida e nenhuma chave são a mesma recusa',
      () async {
        final server = await TestApp.start(householdKey: HouseholdKey(_key));

        final (wrong, wrongBody) = await server.call(
          'GET',
          '/v1/entries',
          token: _wrongKey,
        );
        final (almost, _) = await server.call(
          'GET',
          '/v1/entries',
          token: _key.substring(0, _key.length - 1),
        );
        final (none, _) = await server.call('GET', '/v1/entries');

        expect(wrong, 401);
        expect(errorOf(wrongBody)['code'], 'E-AUTH-03');
        expect(almost, 401);
        expect(none, 401);
      },
    );

    test('servidor sem a chave configurada não a aceita, e a autenticação '
        'por aparelho cadastrado continua valendo', () async {
      final server = await TestApp.start();

      final (byKey, _) = await server.call('GET', '/v1/entries', token: _key);
      final (bySession, _) = await server.call(
        'GET',
        '/v1/entries',
        token: server.token(),
      );

      expect(byKey, 401);
      expect(bySession, 200);
    });

    test('a chave é lida da credencial do systemd, e chave curta demais não '
        'vale como chave', () async {
      final directory = Directory.systemTemp.createTempSync('cajui-chave-');
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/${HouseholdKey.credentialName}')
          .writeAsStringSync('$_key\n');
      File('${directory.path}/curta').writeAsStringSync('abc');

      final loaded = HouseholdKey.load(
        environment: {'CREDENTIALS_DIRECTORY': directory.path},
      );
      final short = HouseholdKey.load(
        environment: const {},
        file: '${directory.path}/curta',
      );
      final missing = HouseholdKey.load(environment: const {});

      expect(loaded?.matches(_key), isTrue);
      expect(loaded?.matches(' $_key '), isTrue, reason: 'espaço não conta');
      expect(short, isNull);
      expect(missing, isNull);
    });
  });
}
