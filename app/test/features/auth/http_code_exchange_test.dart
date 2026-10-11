import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/auth/infrastructure/http_code_exchange.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/fake_server.dart';

/// A web não tem identidade de aparelho.
final class _NoIdentity implements DeviceKeyStore {
  @override
  bool get exists => false;

  @override
  Future<Uint8List> publicKey() async => Uint8List(0);
}

void main() {
  late FakeServer server;
  late HttpCodeExchange exchange;

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
    exchange = HttpCodeExchange(
      CajuiApi(
        baseUrl: server.baseUrl,
        keys: FakeHouseholdKey(null),
        identity: _NoIdentity(),
        client: server.client,
      ),
    );
  });

  group('ADR-027 · a troca do código pelo servidor', () {
    test('o código certo volta como a sessão', () async {
      server.bodies['/v1/auth/code'] = const {'token': 'sessao-de-consulta'};

      final outcome = await exchange.tokenFor('482913');

      expect(outcome.token, 'sessao-de-consulta');
      expect(server.requests.single.body, {'code': '482913'});
    });

    test('E-AUTH-04 · a recusa do servidor (E-AUTH-03) é "esse código não '
        'serviu"', () async {
      server.refuseWith(ErrorCode.auth03);

      final outcome = await exchange.tokenFor('000000');

      expect(outcome.token, isNull);
      expect(outcome.error, ErrorCode.auth04);
    });

    test(
      'E-RATE-01 · o limite de taxa chega como ele é, com a espera',
      () async {
        server.refuseWith(ErrorCode.rate01, status: 429, retryAfterSeconds: 42);

        final outcome = await exchange.tokenFor('482913');

        expect(outcome.error, ErrorCode.rate01);
        expect(outcome.retryAfterSeconds, 42);
      },
    );

    test(
      'E-NET-01 · sem servidor, é falta de rede, e não código errado',
      () async {
        await server.stop();

        final outcome = await exchange.tokenFor('482913');

        expect(outcome.error, ErrorCode.net01);
      },
    );
  });
}
