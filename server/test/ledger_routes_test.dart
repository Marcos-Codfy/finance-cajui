import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

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

  group('lançamentos', () {
    test('cria, grava o evento e lista pelo mês', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
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

    test(
      'T-05 o servidor revalida as regras: soma errada vira E-ENTRY-01',
      () async {
        final lines = [
          {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 5000},
        ];

        final (status, body) = await server.call(
          'POST',
          '/v1/entries',
          body: entryBody(lines: lines),
          token: token,
        );

        expect(status, 422);
        expect(errorOf(body)['code'], 'E-ENTRY-01');
        expect(errorOf(body)['class'], 'regra');
        expect(errorOf(body)['detail'], {
          'amountCents': 8600,
          'linesTotalCents': 5000,
        });
        expect(server.store.events, hasLength(1));
      },
    );

    test('RN-206 data no futuro vira E-ENTRY-02', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(on: '2026-09-21'),
        token: token,
      );

      expect((status, errorOf(body)['code']), (422, 'E-ENTRY-02'));
    });

    test('ADR-012 o mesmo comando duas vezes vira um lançamento só', () async {
      final first = await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
        token: token,
      );
      final again = await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(),
        token: token,
      );

      expect(again.$1, 201);
      expect(again.$2['seq'], first.$2['seq']);
      expect(server.store.events, hasLength(2));
    });

    test(
      'RNF-SEC-09 pedido malformado vira E-REQ-01, nunca erro interno',
      () async {
        final bodies = [
          {...entryBody(), 'isAdmin': true},
          entryBody(on: '2026-02-30'),
          entryBody(
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
          expect((status, errorOf(json)['code']), (400, 'E-REQ-01'));
        }
      },
    );

    test('categoria que não existe vira E-REQ-02', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: {...entryBody(), 'categoryId': 'sumiu'},
        token: token,
      );

      expect((status, errorOf(body)['code']), (404, 'E-REQ-02'));
    });

    test('T-25 corpo acima do teto vira E-REQ-04', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/entries',
        body: {...entryBody(), 'description': 'x' * 70000},
        token: token,
      );

      expect((status, errorOf(body)['code']), (413, 'E-REQ-04'));
    });
  });

  group('classificação de comprovante', () {
    test(
      'ADR-010 sem chave da IA, a rota responde só com as regras locais',
      () async {
        final (status, body) = await server.call(
          'POST',
          '/v1/receipts/classify',
          body: {'text': 'MERCADO BOA COMPRA\nTOTAL 186,40\nPIX\n12/09/2026'},
          token: token,
        );
        final amount = body['amountCents']! as Map<String, Object?>;

        expect(status, 200);
        expect(amount['value'], 18640);
        expect(amount['confidence'], 'high');
        expect(amount['source'], 'fixedRule');
        expect(body['merchant'], 'MERCADO BOA COMPRA');
        expect(body['warnings'], isEmpty);
      },
    );

    test('a rota só aceita texto: qualquer outro campo é recusado', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/receipts/classify',
        body: {'text': 'TOTAL 1,00', 'image': 'base64...'},
        token: token,
      );

      expect((status, errorOf(body)['code']), (400, 'E-REQ-01'));
    });
  });

  group('categorias', () {
    test('RN-207 nome que representa cartão vira E-CARD-02', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/categories',
        body: {...groceriesBody, 'id': 'card', 'name': 'Cartão Nubank'},
        token: token,
      );

      expect((status, errorOf(body)['code']), (422, 'E-CARD-02'));
    });
  });

  group('estado reconstruído', () {
    test('ADR-004 reabrir o registro devolve o mesmo estado', () async {
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);
      final (_, head) = await server.call('GET', '/v1/head', token: token);

      expect(head['seq'], 2);
    });
  });
}
