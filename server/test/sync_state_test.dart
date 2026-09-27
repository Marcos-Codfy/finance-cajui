import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

/// Uma linha só, no Pix, fechando [cents]: a correção de valor precisa de
/// linhas que somem o valor novo (RN-203).
List<Map<String, Object?>> _pixOnly(int cents) => [
  {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': cents},
];

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

  group('BL-062 · o servidor como ponto de encontro de dois aparelhos', () {
    test('o que foi cancelado fica listado, para o outro aparelho cancelar '
        'também', () async {
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);
      await server.call('DELETE', '/v1/entries/e1', token: token);

      final (_, listado) = await server.call(
        'GET',
        '/v1/entries',
        token: token,
      );

      expect(listado['entries'], isEmpty);
      expect(listado['cancelledIds'], ['e1']);
    });

    test('o aparelho que ainda tinha o lançamento não o ressuscita', () async {
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);
      await server.call('DELETE', '/v1/entries/e1', token: token);

      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
        token: token,
      );
      final (_, listado) = await server.call(
        'GET',
        '/v1/entries',
        token: token,
      );

      expect(status, 200);
      expect(body['cancelled'], isTrue);
      expect(listado['entries'], isEmpty, reason: 'continua cancelado');
    });

    test('nem por correção', () async {
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);
      await server.call('DELETE', '/v1/entries/e1', token: token);

      final (status, _) = await server.call(
        'PUT',
        '/v1/entries/e1',
        body: entryBody(cents: 9000),
        token: token,
      );
      final (_, listado) = await server.call(
        'GET',
        '/v1/entries',
        token: token,
      );

      expect(status, 200);
      expect(listado['entries'], isEmpty);
    });

    test(
      'a correção mais velha não apaga a mais nova, mesmo chegando depois',
      () async {
        await server.call(
          'POST',
          '/v1/entries',
          body: entryBody(),
          token: token,
        );
        final nova = {
          ...entryBody(cents: 9900, lines: _pixOnly(9900)),
          'revisedAt': '2026-09-20T11:00:00.000Z',
        };
        final velha = {
          ...entryBody(cents: 7000, lines: _pixOnly(7000)),
          'revisedAt': '2026-09-20T10:00:00.000Z',
        };

        await server.call('PUT', '/v1/entries/e1', body: nova, token: token);
        final (status, body) = await server.call(
          'PUT',
          '/v1/entries/e1',
          body: velha,
          token: token,
        );
        final (_, listado) = await server.call(
          'GET',
          '/v1/entries',
          token: token,
        );
        final entry = (listado['entries']! as List<Object?>).single! as Map;

        expect(status, 200);
        expect(body['kept'], isTrue);
        expect(entry['amountCents'], 9900, reason: 'a velha não apagou');
        expect(entry['revisedAt'], '2026-09-20T11:00:00.000Z');
      },
    );

    test(
      'correção sem carimbo — registro antigo — continua valendo a última',
      () async {
        await server.call(
          'POST',
          '/v1/entries',
          body: entryBody(),
          token: token,
        );

        await server.call(
          'PUT',
          '/v1/entries/e1',
          body: entryBody(cents: 9900, lines: _pixOnly(9900)),
          token: token,
        );
        await server.call(
          'PUT',
          '/v1/entries/e1',
          body: entryBody(cents: 7000, lines: _pixOnly(7000)),
          token: token,
        );
        final (_, listado) = await server.call(
          'GET',
          '/v1/entries',
          token: token,
        );
        final entry = (listado['entries']! as List<Object?>).single! as Map;

        expect(entry['amountCents'], 7000);
      },
    );

    test('carimbo no futuro é recusado: travaria o lançamento para sempre '
        'contra o outro aparelho (T-40)', () async {
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);
      final doFuturo = {
        ...entryBody(cents: 9900, lines: _pixOnly(9900)),
        'revisedAt': '9999-12-31T23:59:59.000Z',
      };
      final plano = {
        ...planBody(cashIncomeCents: 1),
        'definedAt': '9999-12-31T23:59:59.000Z',
      };

      final (status, body) = await server.call(
        'PUT',
        '/v1/entries/e1',
        body: doFuturo,
        token: token,
      );
      final (planStatus, _) = await server.call(
        'POST',
        '/v1/plan',
        body: plano,
        token: token,
      );

      expect(status, 400);
      expect((body['error']! as Map)['code'], 'E-REQ-01');
      expect(planStatus, 400);
    });

    test('cancelar o que nunca existiu é recusado, e não vira cancelado '
        'eterno', () async {
      final (status, _) = await server.call(
        'DELETE',
        '/v1/entries/nunca-existiu',
        token: token,
      );
      final (_, listado) = await server.call(
        'GET',
        '/v1/entries',
        token: token,
      );

      expect(status, 404);
      expect(listado['cancelledIds'], isEmpty);
    });

    test('correção de id desconhecido seguida do lançamento não duplica '
        'ao reler o registro', () async {
      await server.call(
        'PUT',
        '/v1/entries/e1',
        body: entryBody(cents: 5000, lines: _pixOnly(5000)),
        token: token,
      );
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);

      final replayed = LedgerState(server.store.events);

      expect(server.app.sessions, isNotNull);
      expect(replayed.entries.where((e) => e.id == 'e1'), hasLength(1));
    });

    test(
      'o plano mais novo pelo carimbo vence, mesmo chegando antes',
      () async {
        final novo = {
          ...planBody(cashIncomeCents: 200000),
          'definedAt': '2026-09-20T11:00:00.000Z',
        };
        final velho = {
          ...planBody(cashIncomeCents: 100000),
          'definedAt': '2026-09-20T10:00:00.000Z',
        };

        await server.call('POST', '/v1/plan', body: novo, token: token);
        await server.call('POST', '/v1/plan', body: velho, token: token);
        final (_, lido) = await server.call('GET', '/v1/plan', token: token);

        expect(
          lido['cashIncomeCents'],
          200000,
          reason: 'o velho não apagou o novo',
        );
        expect(lido['definedAt'], '2026-09-20T11:00:00.000Z');
      },
    );

    test(
      'plano sem carimbo — registro antigo — continua valendo o último',
      () async {
        await server.call(
          'POST',
          '/v1/plan',
          body: planBody(cashIncomeCents: 100000),
          token: token,
        );
        await server.call(
          'POST',
          '/v1/plan',
          body: planBody(cashIncomeCents: 300000),
          token: token,
        );
        final (_, lido) = await server.call('GET', '/v1/plan', token: token);

        expect(lido['cashIncomeCents'], 300000);
      },
    );
  });
}
