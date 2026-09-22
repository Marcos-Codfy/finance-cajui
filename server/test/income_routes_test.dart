import 'package:server/src/auth/session_scope.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

Map<String, Object?> _receipt({
  String id = 'r1',
  String tender = 'mealVoucher',
  int cents = 50000,
  String on = '2026-09-05',
}) => {
  'id': id,
  'sourceId': 'salario',
  'tender': tender,
  'amountCents': cents,
  'receivedOn': on,
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
  });

  group('BL-060 · o que entrou também atravessa', () {
    test('o recebimento sobe e desce, e o saldo do vale sai junto', () async {
      final (status, _) = await server.call(
        'POST',
        '/v1/income',
        body: _receipt(),
        token: token,
      );
      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(status, 201);
      expect((lido['receipts']! as List).single, _receipt());
      expect(lido['voucherBalanceCents'], 50000);
    });

    test('RN-120 · o que o lançamento paga em vale sai do saldo', () async {
      await server.call('POST', '/v1/income', body: _receipt(), token: token);
      // O lançamento de exemplo paga R$ 30,00 no vale e R$ 56,00 no Pix.
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);

      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(lido['voucherBalanceCents'], 47000);
    });

    test('RN-995 · cancelar o lançamento devolve o vale ao saldo', () async {
      await server.call('POST', '/v1/income', body: _receipt(), token: token);
      await server.call('POST', '/v1/entries', body: entryBody(), token: token);

      await server.call('DELETE', '/v1/entries/e1', token: token);
      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(lido['voucherBalanceCents'], 50000);
    });

    test('RN-123 · o acerto de saldo entra, e pode ser negativo', () async {
      await server.call('POST', '/v1/income', body: _receipt(), token: token);

      final (status, _) = await server.call(
        'POST',
        '/v1/voucher/adjustments',
        body: {
          'id': 'a1',
          'adjustmentCents': -790,
          'on': '2026-09-20',
          'reason': 'o cartão mostrava outro saldo',
        },
        token: token,
      );
      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(status, 201);
      expect(lido['voucherBalanceCents'], 49210);
      expect(lido['voucherAdjustments']! as List, hasLength(1));
    });

    test('RN-122 · o saldo do vale nunca sai negativo', () async {
      await server.call(
        'POST',
        '/v1/voucher/adjustments',
        body: {
          'id': 'a1',
          'adjustmentCents': -5000,
          'on': '2026-09-20',
          'reason': 'acerto',
        },
        token: token,
      );

      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(lido['voucherBalanceCents'], 0);
    });

    test('RN-111 · dinheiro e vale não se somam no que entrou', () async {
      await server.call('POST', '/v1/income', body: _receipt(), token: token);
      await server.call(
        'POST',
        '/v1/income',
        body: _receipt(id: 'r2', tender: 'cash', cents: 320000),
        token: token,
      );

      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(lido['receipts']! as List, hasLength(2));
      expect(
        lido['voucherBalanceCents'],
        50000,
        reason: 'a renda em dinheiro não entra no saldo do vale',
      );
    });

    test('o mesmo recebimento duas vezes não cria fato novo', () async {
      await server.call('POST', '/v1/income', body: _receipt(), token: token);
      await server.call('POST', '/v1/income', body: _receipt(), token: token);

      final (_, lido) = await server.call('GET', '/v1/income', token: token);

      expect(lido['receipts']! as List, hasLength(1));
      expect(lido['voucherBalanceCents'], 50000);
    });

    test('T-05 campo a mais e valor não positivo viram E-REQ-01', () async {
      final (extra, corpo) = await server.call(
        'POST',
        '/v1/income',
        body: {..._receipt(), 'bonus': 1},
        token: token,
      );
      final (zero, _) = await server.call(
        'POST',
        '/v1/income',
        body: _receipt(cents: 0),
        token: token,
      );

      expect(extra, 400);
      expect(errorOf(corpo)['code'], 'E-REQ-01');
      expect(zero, 400);
    });

    test('T-12 a consulta pela web lê e não grava', () async {
      final web = server.token(scope: SessionScope.webReadOnly);

      final (leitura, _) = await server.call('GET', '/v1/income', token: web);
      final (escrita, _) = await server.call(
        'POST',
        '/v1/income',
        body: _receipt(),
        token: web,
      );

      expect(leitura, 200);
      expect(escrita, 403);
    });
  });
}
