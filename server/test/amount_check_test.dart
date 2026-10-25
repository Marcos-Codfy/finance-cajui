import 'package:domain/domain.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/assistant/amount_check.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/sequenced_chat_client.dart';
import 'support/test_app.dart';

/// Um valor no formato da casa, com o espaço que não quebra.
String _brl(String number) => 'R\$${MoneyFormat.nbsp}$number';

/// Sobe o servidor com um mercado de R$ 86,00 já lançado — R$ 30,00 no vale
/// e R$ 56,00 no Pix, que são os valores que o resumo traz.
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

Future<Map<String, Object?>> _ask(TestApp server, String token) async {
  final (_, body) = await server.call(
    'POST',
    '/v1/assistant/ask',
    body: {'message': 'Quanto gastei no mercado?'},
    token: token,
  );
  return body;
}

void main() {
  group('RN-943 · o valor em reais que a Juju escreve tem origem', () {
    test('lê o valor escrito, com milhar, centavos e o espaço da casa', () {
      expect(
        AmountCheck.writtenIn(
          'Sobram ${_brl('1.206,40')} e saem R\$ 35 e R\$ 1,5.',
        ),
        [120640, 3500, 150],
      );
    });

    test('o valor que não está no resumo é o que a conferência aponta', () {
      // O caso de 22/10/2026: o resumo trazia a sobra certa, e a resposta
      // saiu com outra.
      const known = {120640, 487015};

      expect(AmountCheck.unknownIn(r'Sobram R$ 123,45 até aqui.', known), [
        12345,
      ]);
      expect(
        AmountCheck.unknownIn(r'Sobram R$ 1.206,40 neste mês.', known),
        isEmpty,
      );
    });

    test('zero e texto sem valor nunca reprovam', () {
      expect(AmountCheck.unknownIn('Não tenho esse dado.', {}), isEmpty);
      expect(AmountCheck.unknownIn(r'Ficou em R$ 0,00.', {}), isEmpty);
    });

    test('o que a pessoa digitou conta como origem, em reais', () {
      expect(AmountCheck.typedIn('gastei 35,50 e 1.200'), {3550, 120000});
    });

    test('todo inteiro do JSON entra, mesmo fundo', () {
      expect(
        AmountCheck.intsIn({
          'a': 1,
          'b': [
            {'c': 2},
            3,
          ],
          'd': 'x',
        }),
        {1, 2, 3},
      );
    });

    test('resposta com valor inventado volta ao modelo uma vez, com o '
        'valor apontado, e a certa é a que fica', () async {
      final client = SequencedChatClient([
        'Você gastou ${_brl('86,00')}.',
        'No Pix foram ${_brl('56,00')}.',
      ]);
      final (server, token) = await _server(client);

      final body = await _ask(server, token);

      expect(body['text'], 'No Pix foram ${_brl('56,00')}.');
      expect(body['fallback'], isFalse);
      expect(client.calls, hasLength(2));
      expect(client.calls.last.user, contains(_brl('86,00')));
    });

    test('quem insiste no valor inventado recebe a resposta de formato fixo, '
        'e não o número errado', () async {
      final client = SequencedChatClient(['Você gastou ${_brl('86,00')}.']);
      final (server, token) = await _server(client);

      final body = await _ask(server, token);

      expect(body['fallback'], isTrue);
      expect(body['text'], isNot(contains('86,00')));
      expect(client.calls, hasLength(2));
    });
  });
}
