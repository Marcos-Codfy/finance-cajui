import 'package:domain/domain.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

void main() {
  late TestApp server;
  late String token;

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
  });

  group('o plano do mês no servidor (BL-049)', () {
    test('sobe inteiro e desce igual', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/plan',
        body: planBody(),
        token: token,
      );
      final (_, lido) = await server.call('GET', '/v1/plan', token: token);

      expect(status, 200);
      expect(body['seq'], 1);
      expect(lido['cashIncomeCents'], 320000);
      expect(lido['debtInstallmentsCents'], 45000);
      expect(
        (lido['fixed']! as List).single,
        (planBody()['fixed']! as List).single,
      );
      expect(
        (lido['variables']! as List).single,
        (planBody()['variables']! as List).single,
      );
      expect(server.store.events.last.type, 'plan.defined');
    });

    test('servidor que nunca recebeu plano devolve um plano vazio', () async {
      final (status, body) = await server.call('GET', '/v1/plan', token: token);

      expect(status, 200);
      expect(body['cashIncomeCents'], 0);
      expect(body['fixed'], isEmpty);
    });

    test('mandar o mesmo plano duas vezes não cria fato novo', () async {
      await server.call('POST', '/v1/plan', body: planBody(), token: token);
      await server.call('POST', '/v1/plan', body: planBody(), token: token);

      expect(server.store.events, hasLength(1));
    });

    test('plano diferente cria fato novo, e o último vale', () async {
      await server.call('POST', '/v1/plan', body: planBody(), token: token);
      await server.call(
        'POST',
        '/v1/plan',
        body: planBody(cashIncomeCents: 400000),
        token: token,
      );
      final (_, lido) = await server.call('GET', '/v1/plan', token: token);

      expect(server.store.events, hasLength(2));
      expect(lido['cashIncomeCents'], 400000);
    });

    test(
      'o plano sobrevive ao servidor reiniciar: é evento, não memória',
      () async {
        await server.call('POST', '/v1/plan', body: planBody(), token: token);

        final revivido = LedgerState(server.store.events);

        expect(revivido.plan.cashIncome, const Money.fromCents(320000));
        expect(revivido.plan.fixedExpenses.single.name, 'Aluguel');
      },
    );

    test('T-12 a consulta pela web não grava plano', () async {
      final web = server.token(scope: SessionScope.webReadOnly);

      final (escrita, _) = await server.call(
        'POST',
        '/v1/plan',
        body: planBody(),
        token: web,
      );
      final (leitura, _) = await server.call('GET', '/v1/plan', token: web);

      expect(escrita, 403);
      expect(leitura, 200);
    });

    test('T-05 campo a mais no plano vira E-REQ-01', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/plan',
        body: {...planBody(), 'limiteSecreto': 1},
        token: token,
      );

      expect(status, 400);
      expect(errorOf(body)['code'], 'E-REQ-01');
    });

    test('T-05 renda negativa vira E-REQ-01', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/plan',
        body: planBody(cashIncomeCents: -500),
        token: token,
      );

      expect(status, 400);
      expect(errorOf(body)['code'], 'E-REQ-01');
    });

    test('sem token não se lê nem se grava plano', () async {
      final (leitura, _) = await server.call('GET', '/v1/plan');
      final (escrita, _) = await server.call(
        'POST',
        '/v1/plan',
        body: planBody(),
      );

      expect(leitura, 401);
      expect(escrita, 401);
    });
  });
}
