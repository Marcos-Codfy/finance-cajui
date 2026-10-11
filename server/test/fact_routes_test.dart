import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

Map<String, Object?> _debt({String id = 'fato-divida', int paid = 5}) => {
  'id': id,
  'type': 'debt.defined',
  'payload': {
    'id': 'debt-1',
    'creditor': 'Banco do bairro',
    'kind': 'loan',
    'installmentCents': 21200,
    'totalInstallments': 12,
    'paidInstallments': paid,
    'dueDay': 10,
    'firstMonth': '2026-04',
    'cardId': null,
    'payoffCents': null,
    'payoffQuotedOn': null,
  },
};

const Map<String, Object?> _settled = {
  'id': 'settlement-s1',
  'type': 'statement.settled',
  'payload': {
    'id': 's1',
    'cardId': 'card-1',
    'dueMonth': '2026-10',
    'amountCents': 80000,
    'paidOn': '2026-10-05',
  },
};

void main() {
  late TestApp server;
  late String token;

  setUp(() async {
    server = await TestApp.start();
    token = server.token();
  });

  Future<List<Object?>> listed() async {
    final (_, body) = await server.call('GET', '/v1/facts', token: token);
    return body['facts']! as List<Object?>;
  }

  group('ADR-019 · os fatos que o servidor guarda para o outro celular', () {
    test('o que um aparelho manda, o outro encontra, na ordem em que '
        'chegou', () async {
      final (status, _) = await server.call(
        'POST',
        '/v1/facts',
        body: _debt(),
        token: token,
      );
      await server.call('POST', '/v1/facts', body: _settled, token: token);

      final facts = await listed();

      expect(status, 201);
      expect(facts, hasLength(2));
      expect((facts.first! as Map)['type'], 'debt.defined');
      expect((facts.last! as Map)['id'], 'settlement-s1');
    });

    test('mandar de novo não guarda de novo', () async {
      await server.call('POST', '/v1/facts', body: _debt(), token: token);
      await server.call('POST', '/v1/facts', body: _debt(), token: token);

      expect(await listed(), hasLength(1));
    });

    test('os fatos sobrevivem ao reinício: a projeção se refaz do '
        'registro', () async {
      await server.call('POST', '/v1/facts', body: _debt(), token: token);
      await server.call('POST', '/v1/facts', body: _settled, token: token);

      final replayed = LedgerState(server.store.events);

      expect(replayed.facts.map((fact) => fact.id), [
        'fato-divida',
        'settlement-s1',
      ]);
    });

    test('T-05 · conteúdo que o domínio recusa não é guardado '
        '(E-REQ-01)', () async {
      final (status, body) = await server.call(
        'POST',
        '/v1/facts',
        body: _debt(paid: 99),
        token: token,
      );

      expect(status, 400);
      expect((body['error']! as Map)['code'], 'E-REQ-01');
      expect(await listed(), isEmpty);
    });

    test('tipo que não é um dos quatro é recusado: lançamento não entra por '
        'esta porta', () async {
      final (status, _) = await server.call(
        'POST',
        '/v1/facts',
        body: {
          'id': 'x',
          'type': 'entry.created',
          'payload': const <String, Object?>{},
        },
        token: token,
      );

      expect(status, 400);
      expect(await listed(), isEmpty);
    });

    test('RN-906 · a web lê os fatos, e não grava nenhum', () async {
      await server.call('POST', '/v1/facts', body: _debt(), token: token);
      final web = server.token(scope: SessionScope.webReadOnly);

      final (lido, body) = await server.call('GET', '/v1/facts', token: web);
      final (gravado, _) = await server.call(
        'POST',
        '/v1/facts',
        body: _settled,
        token: web,
      );

      expect(lido, 200);
      expect(body['facts']! as List<Object?>, hasLength(1));
      expect(gravado, 403);
    });

    test('RN-1070 · os nomes da casa são guardados para o outro celular, e '
        'nome sem sobrenome é recusado', () async {
      Map<String, Object?> named(List<String> names) => {
        'id': 'household-2026-10-11T12:00:00.000Z',
        'type': 'household.named',
        'payload': {'names': names, 'definedAt': '2026-10-11T12:00:00.000Z'},
      };

      final (recusado, _) = await server.call(
        'POST',
        '/v1/facts',
        body: named(['Marcos']),
        token: token,
      );
      final (aceito, _) = await server.call(
        'POST',
        '/v1/facts',
        body: named(['Marcos Arruda', 'Beatriz Souza Lima']),
        token: token,
      );
      final facts = await listed();

      expect(recusado, 400);
      expect(aceito, 201);
      final payload = (facts.single! as Map)['payload']! as Map;
      expect(payload['names'], ['Marcos Arruda', 'Beatriz Souza Lima']);
    });

    test('sem sessão, nada se lê nem se grava', () async {
      final (lido, _) = await server.call('GET', '/v1/facts');
      final (gravado, _) = await server.call(
        'POST',
        '/v1/facts',
        body: _debt(),
      );

      expect(lido, 401);
      expect(gravado, 401);
    });
  });
}
