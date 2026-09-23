import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

Map<String, Object?> _reversal({
  String id = 'r1',
  String entryId = 'e1',
  String method = 'pix',
  int cents = 5600,
  String on = '2026-09-20',
}) => {
  'id': id,
  'entryId': entryId,
  'paymentMethodId': method,
  'amountCents': cents,
  'occurredOn': on,
};

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
    // R$ 86,00: R$ 30,00 no vale e R$ 56,00 no Pix.
    await server.call('POST', '/v1/entries', body: entryBody(), token: token);
  });

  group('RN-209 · o estorno atravessa até o servidor', () {
    test(
      'o dinheiro que voltou vira fato, e não altera o lançamento',
      () async {
        final (status, body) = await server.call(
          'POST',
          '/v1/entries/e1/reversals',
          body: _reversal(),
          token: token,
        );
        final (_, listado) = await server.call(
          'GET',
          '/v1/entries',
          token: token,
        );

        expect(status, 201);
        expect(body['id'], 'r1');
        expect(server.store.events.last.type, 'entry.reversed');
        final entrada = (listado['entries']! as List).single;
        expect(
          (entrada! as Map)['amountCents'],
          8600,
          reason: 'RN-208: o lançamento original continua como era',
        );
      },
    );

    test('RN-210 · estornar mais do que resta na linha é recusado', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries/e1/reversals',
        body: _reversal(cents: 9000),
        token: token,
      );

      expect(status, 422);
      expect(errorOf(body)['code'], 'E-ENTRY-04');
    });

    test(
      'RN-210 · dois estornos que juntos passam do valor: o segundo cai',
      () async {
        await server.call(
          'POST',
          '/v1/entries/e1/reversals',
          body: _reversal(cents: 4000),
          token: token,
        );

        final (status, _) = await server.call(
          'POST',
          '/v1/entries/e1/reversals',
          body: _reversal(id: 'r2', cents: 2000),
          token: token,
        );

        expect(status, 422, reason: '4000 + 2000 passa dos 5600 do Pix');
      },
    );

    test(
      'RN-211 · estornar por forma que o lançamento não usou é recusado',
      () async {
        final (status, _) = await server.call(
          'POST',
          '/v1/entries/e1/reversals',
          body: _reversal(method: 'boleto', cents: 100),
          token: token,
        );

        expect(status, 422);
      },
    );

    test(
      'estorno de lançamento que o servidor não conhece é E-REQ-02',
      () async {
        final (status, body) = await server.call(
          'POST',
          '/v1/entries/nao-existe/reversals',
          body: _reversal(entryId: 'nao-existe'),
          token: token,
        );

        expect(status, 404);
        expect(errorOf(body)['code'], 'E-REQ-02');
      },
    );
  });
}
