import 'dart:convert';

import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

/// A chave da casa do teste.
const _key = 'chave-da-casa-de-teste-com-tamanho-bom';

ChatReply _text(String content) =>
    ChatReply(content: content, promptTokens: 900, completionTokens: 60);

ChatReply _calls(List<ToolCall> calls) => ChatReply(
  content: '',
  toolCalls: calls,
  promptTokens: 900,
  completionTokens: 30,
);

ToolCall _call(
  String name,
  Map<String, Object?> arguments, {
  String id = 'c1',
}) => ToolCall(id: id, name: name, arguments: arguments);

/// Sobe o servidor com a categoria Mercado e o mercado de R$ 86,00 (R$ 30,00
/// no vale, R$ 56,00 no Pix) já lançados, e a IA falando com [client].
Future<(TestApp, String)> _server(ToolChatClient client) async {
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

Future<(int, Map<String, Object?>)> _ask(
  TestApp server,
  String token,
  String message,
) => server.call(
  'POST',
  '/v1/assistant/ask',
  body: {'message': message},
  token: token,
);

/// O resultado que a ferramenta devolveu ao modelo na conversa [index].
Map<String, Object?> _toolResult(ToolChatClient client, int index) {
  final message = client.conversations[index].lastWhere(
    (message) => message.role == ChatRole.tool,
  );
  return jsonDecode(message.content) as Map<String, Object?>;
}

void main() {
  group('ADR-021 · o assistente age pelo dono', () {
    test('"gastei 50 na padaria" vira um lançamento de verdade, com a ação '
        'dita ao app', () async {
      final client = ToolChatClient([
        _calls([
          _call('lancar_despesa', {
            'descricao': 'Padaria',
            'valor_centavos': 5000,
            'categoria_id': 'groceries',
            'forma': 'débito',
          }),
        ]),
        _text(r'Lancei R$ 50,00 em Mercado, no débito, hoje.'),
      ]);
      final (server, token) = await _server(client);

      final (status, body) = await _ask(server, token, 'gastei 50 na padaria');
      final (_, entries) = await server.call(
        'GET',
        '/v1/entries',
        token: token,
      );
      final recorded = (entries['entries']! as List).last as Map;
      final action = (body['actions']! as List).single as Map;

      expect(status, 200);
      expect(body['text'], startsWith('Lancei'));
      expect(action['kind'], 'recorded');
      expect(action['amountCents'], 5000);
      expect(recorded['description'], 'Padaria');
      expect(recorded['amountCents'], 5000);
      expect(recorded['occurredOn'], '2026-09-20');
      final line = (recorded['paymentLines'] as List).single as Map;
      expect(line['paymentMethodId'], 'debit');
      expect(line['kind'], 'debit');
      expect(_toolResult(client, 1)['ok'], isTrue);
      // A segunda chamada leva o pedido e o resultado da ferramenta.
      expect(
        client.conversations[1].map((m) => m.role),
        contains(ChatRole.tool),
      );
    });

    test('categoria que não existe volta ao modelo como motivo, com a lista '
        'certa, e nada é gravado', () async {
      final client = ToolChatClient([
        _calls([
          _call('lancar_despesa', {
            'valor_centavos': 1200,
            'categoria_id': 'lazer',
          }),
        ]),
        _text('Não achei a categoria.'),
      ]);
      final (server, token) = await _server(client);
      final before = server.store.events.length;

      final (status, body) = await _ask(server, token, 'gastei 12 no cinema');
      final result = _toolResult(client, 1);

      expect(status, 200);
      expect(result['erro'], contains('groceries'));
      expect(body['actions'], isEmpty);
      expect(
        server.store.events
            .where((e) => e.type != TokenBudget.usageRecorded)
            .length,
        before,
      );
    });

    test('"desfaz" cancela pelo id, e o cancelado some da lista', () async {
      final client = ToolChatClient([
        _calls([
          _call('cancelar_lancamento', {'id': 'e1'}),
        ]),
        _text(r'Cancelei o mercado de R$ 86,00.'),
      ]);
      final (server, token) = await _server(client);

      final (_, body) = await _ask(server, token, 'desfaz o mercado');
      final (_, entries) = await server.call(
        'GET',
        '/v1/entries',
        token: token,
      );
      final action = (body['actions']! as List).single as Map;

      expect(action['kind'], 'cancelled');
      expect(action['label'], 'Mercado Boa Compra');
      expect(entries['entries'], isEmpty);
      expect(entries['cancelledIds'], ['e1']);
    });

    test('listar traz nome, forma de pagamento e totais por moeda, nunca '
        'somados (RN-111)', () async {
      final client = ToolChatClient([
        _calls([_call('listar_lancamentos', const {})]),
        _text(r'Em setembro você gastou R$ 56,00 em dinheiro.'),
      ]);
      final (server, token) = await _server(client);

      await _ask(server, token, 'o que gastei esse mês?');
      final listing = _toolResult(client, 1);
      final line = (listing['lancamentos']! as List).single as Map;

      expect(listing['gasto_centavos_dinheiro'], 5600);
      expect(listing['gasto_centavos_vale'], 3000);
      expect(listing, isNot(contains('gasto_centavos_total')));
      expect(line['descricao'], 'Mercado Boa Compra');
      expect(line['forma'], 'Vale alimentação + Pix');
      expect(line['id'], 'e1');
    });

    test('"caiu o salário" sem salário na planilha entra como dinheiro '
        'extra: o dinheiro entrou, e não há esperado para trocar', () async {
      final client = ToolChatClient([
        _calls([
          _call('registrar_renda', {'valor_centavos': 320000}),
        ]),
        _text(r'Registrei R$ 3.200,00 de salário.'),
      ]);
      final (server, token) = await _server(client);

      final (_, body) = await _ask(server, token, 'caiu o salário, 3200');
      final (_, income) = await server.call('GET', '/v1/income', token: token);
      final receipt = (income['receipts']! as List).single as Map;
      final action = (body['actions']! as List).single as Map;

      expect(action['kind'], 'income');
      expect(receipt['amountCents'], 320000);
      expect(receipt['tender'], 'cash');
      expect(receipt['sourceId'], isNull);
      expect(action['label'], 'Dinheiro extra');
    });

    test('modelo que só pede ferramenta perde as ferramentas na última '
        'rodada, e a resposta de formato fixo conta o que foi feito', () async {
      final client = ToolChatClient([
        _calls([_call('listar_lancamentos', const {})]),
      ]);
      final (server, token) = await _server(client);

      final (status, body) = await _ask(server, token, 'e aí?');

      expect(status, 200);
      expect(body['fallback'], isTrue);
      expect(
        client.offered.last,
        isEmpty,
        reason: 'última rodada sem ferramentas',
      );
      expect(client.offered.first, isNotEmpty);
      expect(
        client.conversations,
        hasLength(AssistantService.maxToolRounds + 1),
      );
    });

    test('a conversa de cada aparelho é a sua: o cabeçalho do aparelho '
        'separa as janelas', () async {
      // Com a chave da casa, quem diz o aparelho é o cabeçalho (ADR-020).
      final client = ToolChatClient([_text('Oi.')]);
      final server = await TestApp.start(
        householdKey: HouseholdKey(_key),
        assistant: (store) => AssistantService(
          client: client,
          budget: TokenBudget(store, monthlyLimit: 1000000),
          breaker: CircuitBreaker(),
        ),
      );

      await server.call(
        'POST',
        '/v1/assistant/ask',
        body: {'message': 'primeira do S22'},
        token: _key,
        headers: const {'x-cajui-device': 'S22'},
      );
      await server.call(
        'POST',
        '/v1/assistant/ask',
        body: {'message': 'primeira do Poco'},
        token: _key,
        headers: const {'x-cajui-device': 'Poco'},
      );
      final talk = client.conversations.last
          .where((m) => m.role != ChatRole.system)
          .map((m) => m.content);

      expect(talk, isNot(contains('primeira do S22')));
      expect(talk, contains('primeira do Poco'));
    });
  });
}
