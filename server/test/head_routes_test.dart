import 'package:server/src/ai/token_budget.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

/// O topo do registro (ADR-024): a pergunta de 20 em 20 segundos com que os
/// aparelhos descobrem se há o que descer.
void main() {
  late TestApp server;

  setUp(() async {
    server = await TestApp.start();
  });

  Future<Map<String, Object?>> head() async {
    final (status, body) = await server.call(
      'GET',
      '/v1/head',
      token: server.token(),
    );
    expect(status, 200);
    return body;
  }

  group('ADR-024 · GET /v1/head', () {
    test(
      'responde seq e ledgerSeq, e o registro vazio é zero e zero',
      () async {
        expect(await head(), {'seq': 0, 'ledgerSeq': 0});
      },
    );

    test('cada fato do livro move os dois juntos', () async {
      await server.call(
        'POST',
        '/v1/categories',
        body: groceriesBody,
        token: server.token(),
      );
      await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
        token: server.token(),
      );

      expect(await head(), {'seq': 2, 'ledgerSeq': 2});
    });

    test('o uso da IA move o seq e **não** o ledgerSeq: perguntar ao '
        'assistente não faz os aparelhos descerem o livro', () async {
      await server.call(
        'POST',
        '/v1/categories',
        body: groceriesBody,
        token: server.token(),
      );
      await server.store.append(
        id: 'uso-1',
        type: TokenBudget.usageRecorded,
        payload: const {'promptTokens': 400, 'completionTokens': 40},
      );

      expect(await head(), {'seq': 2, 'ledgerSeq': 1});
    });

    test('o mesmo pedido de novo não move nada, nem para trás', () async {
      await server.call(
        'POST',
        '/v1/categories',
        body: groceriesBody,
        token: server.token(),
      );
      await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
        token: server.token(),
      );

      await server.call(
        'POST',
        '/v1/categories',
        body: groceriesBody,
        token: server.token(),
      );
      await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
        token: server.token(),
      );

      expect(await head(), {'seq': 2, 'ledgerSeq': 2});
    });

    test('sem a chave da casa, nem o topo responde', () async {
      final (status, body) = await server.call('GET', '/v1/head');

      expect(status, 401);
      expect(errorOf(body)['code'], 'E-AUTH-03');
    });
  });

  group('ADR-024 · o registro de antes da chave da casa', () {
    test('aparelho cadastrado e revogado do jeito antigo fica no registro, '
        'é ignorado ao subir e não conta como mudança do livro', () async {
      final old = await TestApp.start(
        seed: (store) async {
          await store.append(
            id: 'device-s22',
            type: 'device.enrolled',
            payload: const {
              'deviceId': 's22',
              'name': 'Celular',
              'publicKey': 'AAAA',
              'kind': 'device',
            },
          );
          await store.append(
            id: 'category-groceries',
            type: 'category.created',
            payload: groceriesBody,
          );
          await store.append(
            id: 'device-revoked-s22',
            type: 'device.revoked',
            payload: const {'deviceId': 's22'},
          );
        },
      );

      final (status, body) = await old.call(
        'GET',
        '/v1/categories',
        token: old.token(),
      );
      final (_, top) = await old.call('GET', '/v1/head', token: old.token());

      expect(status, 200);
      expect(body['categories'], hasLength(1));
      expect(top, {'seq': 3, 'ledgerSeq': 2});
    });
  });
}
