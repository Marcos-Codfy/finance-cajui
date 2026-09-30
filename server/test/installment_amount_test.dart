import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

/// Uma compra de R$ 100,00 em 3× no cartão, com o valor de parcela dado.
Map<String, Object?> _purchase(int each) => {
  ...entryBody(
    cents: 10000,
    lines: [
      {'paymentMethodId': 'card-1', 'kind': 'creditCard', 'amountCents': 10000},
    ],
  ),
  'installments': 3,
  'installmentAmountCents': each,
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
    await server.call(
      'POST',
      '/v1/cards',
      body: {'id': 'card-1', 'name': 'Cartão', 'closingDay': 25, 'dueDay': 5},
      token: token,
    );
  });

  group('BL-063 · o valor da parcela que chega do aparelho', () {
    test('parcela que soma menos que a compra entra dividida em partes '
        'iguais — e o servidor volta a subir com ela no registro', () async {
      final (status, _) = await server.call(
        'POST',
        '/v1/entries',
        body: _purchase(3333),
        token: token,
      );

      final replayed = LedgerState(server.store.events);
      final plan = replayed.entries.single.installmentPlan!;

      expect(status, 201);
      expect(plan.total.cents, 10000);
      expect(plan.interestTotal.isZero, isTrue);
    });

    test('RN-314 · parcela com juros é guardada e devolvida', () async {
      await server.call(
        'POST',
        '/v1/entries',
        body: _purchase(3600),
        token: token,
      );

      final (_, listed) = await server.call('GET', '/v1/entries', token: token);
      final entry = (listed['entries']! as List<Object?>).single! as Map;

      expect(entry['installmentAmountCents'], 3600);
    });

    test(
      'parcela maior que a compra inteira não é juros: é ignorada',
      () async {
        await server.call(
          'POST',
          '/v1/entries',
          body: _purchase(99999999999),
          token: token,
        );

        final replayed = LedgerState(server.store.events);

        expect(replayed.entries.single.installmentPlan!.total.cents, 10000);
      },
    );
  });
}
