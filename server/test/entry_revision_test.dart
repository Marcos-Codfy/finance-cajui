import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

/// Lançamento corrigido e lançamento cancelado, chegando do celular.
///
/// O servidor precisa acompanhar as duas coisas: sem elas, o contexto do
/// assistente mostraria valor antigo e despesa que já foi cancelada.
void main() {
  late TestApp server;
  late String token;

  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) => server.call(method, path, body: body, token: token);

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
    await call('POST', '/v1/categories', body: groceriesBody);
    await call('POST', '/v1/entries', body: entryBody());
  });

  group('RN-208 · corrigir não reescreve, acrescenta', () {
    test(
      'a correção passa a valer, e o fato antigo continua no registro',
      () async {
        final (status, _) = await call(
          'PUT',
          '/v1/entries/e1',
          body: entryBody(
            cents: 9000,
            lines: [
              {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 9000},
            ],
          ),
        );

        final (_, listed) = await call('GET', '/v1/entries');
        final entries = listed['entries']! as List<Object?>;
        expect(status, 200);
        expect(entries, hasLength(1), reason: 'corrigir não duplica a linha');
        expect((entries.single! as Map<String, Object?>)['amountCents'], 9000);
        expect(
          server.store.events.map((e) => e.type),
          contains('entry.created'),
        );
        expect(server.store.events.last.type, 'entry.revised');
      },
    );

    test('a mesma correção mandada duas vezes grava um fato só', () async {
      final corrected = entryBody(
        cents: 9000,
        lines: [
          {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 9000},
        ],
      );

      await call('PUT', '/v1/entries/e1', body: corrected);
      final antes = server.store.events.length;
      await call('PUT', '/v1/entries/e1', body: corrected);

      expect(server.store.events, hasLength(antes));
    });

    test('correção com identificador de outro lançamento é recusada', () async {
      // O endereço e o corpo têm de falar do mesmo lançamento; discordando,
      // o servidor não escolhe um dos dois.
      final (status, body) = await call(
        'PUT',
        '/v1/entries/outro',
        body: entryBody(),
      );

      expect(status, 404);
      expect(errorOf(body)['code'], 'E-REQ-02');
    });
  });

  group('RN-995 · o cancelado sai de toda visão, e fica no registro', () {
    test('cancelar tira da lista sem apagar o fato', () async {
      final (status, _) = await call('DELETE', '/v1/entries/e1');

      final (_, listed) = await call('GET', '/v1/entries');
      expect(status, 200);
      expect(listed['entries'], isEmpty);
      expect(server.store.events.last.type, 'entry.cancelled');
    });

    test('cancelar duas vezes grava um fato só', () async {
      await call('DELETE', '/v1/entries/e1');
      final antes = server.store.events.length;
      await call('DELETE', '/v1/entries/e1');

      expect(server.store.events, hasLength(antes));
    });
  });
}
