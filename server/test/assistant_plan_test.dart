import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/sequenced_chat_client.dart';
import 'support/test_app.dart';

/// Sobe o servidor com um mercado de R$ 86,00 já lançado e a IA falando com
/// [client]. É o mesmo cenário do teste do contexto, sem o plano.
Future<(TestApp, String)> _server(SequencedChatClient client) async {
  final server = await TestApp.start(
    assistant: (store) => AssistantService(
      client: client,
      budget: TokenBudget(store, monthlyLimit: 1000000),
      breaker: CircuitBreaker(),
    ),
  );
  final token = server.token();
  await server.call(
    'POST',
    '/v1/categories',
    body: groceriesBody,
    token: token,
  );
  await server.call('POST', '/v1/entries', body: entryBody(), token: token);
  return (server, token);
}

Future<void> _ask(TestApp server, String token, String message) => server.call(
  'POST',
  '/v1/assistant/ask',
  body: {'message': message},
  token: token,
);

/// A resposta do modelo é texto puro (ADR-021).
String _reply(String text) => text;

void main() {
  group('BL-049 · o plano do mês no contexto do assistente', () {
    test('entra com natureza "plan", e o teto do que o vale paga não vira '
        'teto em dinheiro (RN-111)', () async {
      final client = SequencedChatClient([_reply('Certo.')]);
      final (server, token) = await _server(client);
      await server.call('POST', '/v1/plan', body: planBody(), token: token);

      await _ask(server, token, 'Quanto ainda posso gastar?');
      final sent = client.calls.single.system;

      expect(sent, contains('"kind":"plan"'));
      expect(sent, contains('Renda planejada, em dinheiro'));
      expect(sent, contains('"cents":320000'));
      expect(sent, contains('Contas fixas planejadas, em dinheiro'));
      expect(sent, contains('"cents":120000'));
      // A faixa do mercado é elegível ao vale: o teto sai "no vale".
      expect(sent, contains('Teto dos gastos variáveis, no vale'));
      expect(sent, isNot(contains('Teto dos gastos variáveis, em dinheiro')));
    });

    test('RN-912 · o contexto não cresce com o tamanho do plano: trinta '
        'contas fixas viram o mesmo número que uma', () async {
      final client = SequencedChatClient([_reply('Certo.')]);
      final (server, token) = await _server(client);
      await server.call(
        'POST',
        '/v1/plan',
        body: {
          ...planBody(),
          'fixed': [
            for (var i = 0; i < 30; i++)
              {
                'id': 'fixo-$i',
                'name': 'Conta $i',
                'amountCents': 1000,
                'dueDay': 5,
                'categoryId': 'housing',
                'paymentMethodId': 'pix',
              },
          ],
        },
        token: token,
      );

      await _ask(server, token, 'Quanto ainda posso gastar?');
      final sent = client.calls.single.system;

      expect('"kind":"plan"'.allMatches(sent), hasLength(4));
      expect(sent, isNot(contains('Conta 7')));
      // Trinta contas de R$ 10,00 viram um número só, de R$ 300,00.
      expect(sent, contains('"cents":30000'));
    });

    test(
      'BL-060 · o saldo do vale e a renda recebida entram como fato, e o '
      'saldo não leva mês: ele passa inteiro para o seguinte (RN-121)',
      () async {
        final client = SequencedChatClient([_reply('Certo.')]);
        final (server, token) = await _server(client);
        await server.call(
          'POST',
          '/v1/income',
          body: const {
            'id': 'r1',
            'sourceId': 'vale',
            'tender': 'mealVoucher',
            'amountCents': 50000,
            'receivedOn': '2026-09-05',
          },
          token: token,
        );

        await _ask(server, token, 'Quanto ainda tenho de vale?');
        final sent = client.calls.single.system;

        // R$ 500,00 de crédito menos os R$ 30,00 que o mercado pagou no vale.
        expect(sent, contains('Saldo do vale hoje'));
        expect(sent, contains('"cents":47000'));
        expect(sent, contains('"period":"acumulado"'));
        expect(sent, contains('Renda recebida, no vale'));
      },
    );

    test('RN-209 · depois de uma devolução, o contexto para de contar o '
        'gasto cheio', () async {
      final client = SequencedChatClient([_reply('Certo.')]);
      final (server, token) = await _server(client);
      // O mercado de R$ 86,00 teve R$ 56,00 devolvidos pelo Pix.
      await server.call(
        'POST',
        '/v1/entries/e1/reversals',
        body: const {
          'id': 'r1',
          'entryId': 'e1',
          'paymentMethodId': 'pix',
          'amountCents': 5600,
          'occurredOn': '2026-09-20',
        },
        token: token,
      );

      await _ask(server, token, 'Quanto gastei?');
      final sent = client.calls.single.system;

      expect(sent, isNot(contains('"cents":5600')));
      expect(
        sent,
        contains('"cents":3000'),
        reason: 'o vale não foi devolvido',
      );
    });

    test('sem plano cadastrado o contexto não ganha número nenhum a mais: '
        'quem não planejou não paga token por isso', () async {
      final client = SequencedChatClient([_reply('Certo.')]);
      final (server, token) = await _server(client);

      await _ask(server, token, 'Quanto gastei?');

      expect(client.calls.single.system, isNot(contains('"kind":"plan"')));
    });
  });
}
