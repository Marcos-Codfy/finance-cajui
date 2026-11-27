import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

ChatReply _text(String content) =>
    ChatReply(content: content, promptTokens: 900, completionTokens: 60);

ChatReply _calls(String name, Map<String, Object?> arguments) => ChatReply(
  content: '',
  toolCalls: [ToolCall(id: 'c1', name: name, arguments: arguments)],
  promptTokens: 900,
  completionTokens: 30,
);

/// O mercado de hoje (20/09 no relógio do teste), R$ 86,00 no Pix: igual
/// ao que já está lançado.
const Map<String, Object?> _market = {
  'descricao': 'Mercado',
  'valor_centavos': 8600,
  'categoria_id': 'groceries',
  'forma': 'pix',
};

/// Uma IA que pede para lançar um gasto novo e cai na chamada seguinte,
/// antes de redigir a resposta: o caso em que a pessoa lia "fora do ar".
final class _FallsAfterWriting extends ChatClient {
  int calls = 0;

  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) => throw const ChatUnavailable(status: 503);

  @override
  Future<ChatReply> converse({
    required List<ChatMessage> messages,
    required int maxTokens,
    List<ChatTool> tools = const [],
    bool json = false,
  }) async {
    calls++;
    if (calls > 1) throw const ChatUnavailable(status: 503);
    return _calls('lancar_despesa', {..._market, 'valor_centavos': 1200});
  }
}

/// O servidor com a categoria Mercado e o mercado de hoje já lançado.
Future<(TestApp, String)> _server(ChatClient client) async {
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
  await server.call(
    'POST',
    '/v1/entries',
    body: entryBody(
      on: '2026-09-20',
      lines: const [
        {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 8600},
      ],
    ),
    token: token,
  );
  return (server, token);
}

Future<(int, Map<String, Object?>)> _ask(TestApp server, String token) =>
    server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': 'gastei 86 no mercado'},
      token: token,
    );

Future<List<Map<String, Object?>>> _entries(
  TestApp server,
  String token,
) async {
  final (_, body) = await server.call('GET', '/v1/entries', token: token);
  return [
    for (final entry in body['entries']! as List) entry as Map<String, Object?>,
  ];
}

void main() {
  group('a Juju não lança em dobro', () {
    test('o mesmo valor, no mesmo dia e na mesma forma volta como pergunta, '
        'e nada é gravado', () async {
      final client = ToolChatClient([
        _calls('lancar_despesa', _market),
        _text('Esse já está lançado. É outro gasto?'),
      ]);
      final (server, token) = await _server(client);

      final (status, body) = await _ask(server, token);

      expect(status, 200);
      expect(body['actions'], isEmpty);
      expect(await _entries(server, token), hasLength(1));
    });

    test('com "repetido", depois de a pessoa confirmar, o segundo entra: '
        'dois gastos iguais existem', () async {
      final client = ToolChatClient([
        _calls('lancar_despesa', {..._market, 'repetido': true}),
        _text(r'Lancei R$ 86,00 em Mercado, no Pix.'),
      ]);
      final (server, token) = await _server(client);

      await _ask(server, token);

      expect(await _entries(server, token), hasLength(2));
    });

    test('a IA caiu depois de lançar: a resposta diz o que foi feito, com '
        'a ação, em vez de "fora do ar"', () async {
      final (server, token) = await _server(_FallsAfterWriting());

      final (status, body) = await _ask(server, token);

      expect(status, 200);
      expect(body['fallback'], isTrue);
      expect(body['actions'], hasLength(1));
      expect(body['text'], contains('Fiz o que você pediu'));
      expect(await _entries(server, token), hasLength(2));
    });
  });

  group('corrigir substitui, nunca soma', () {
    test(r'"era 50, não 86": o mesmo lançamento passa a valer R$ 50,00, e '
        'continua um só', () async {
      final client = ToolChatClient([
        _calls('corrigir_lancamento', {'id': 'e1', 'valor_centavos': 5000}),
        _text(r'Corrigi para R$ 50,00.'),
      ]);
      final (server, token) = await _server(client);

      final (status, _) = await _ask(server, token);
      final entries = await _entries(server, token);

      expect(status, 200);
      expect(entries, hasLength(1));
      expect(entries.single['amountCents'], 5000);
      final line = (entries.single['paymentLines']! as List).single as Map;
      expect(line['amountCents'], 5000);
    });

    test('data e forma também se corrigem; o que não veio fica', () async {
      final client = ToolChatClient([
        _calls('corrigir_lancamento', {
          'id': 'e1',
          'data': '2026-09-19',
          'forma': 'débito',
        }),
        _text('Corrigi.'),
      ]);
      final (server, token) = await _server(client);

      await _ask(server, token);
      final entry = (await _entries(server, token)).single;

      expect(entry['occurredOn'], '2026-09-19');
      expect(entry['amountCents'], 8600);
      expect(entry['description'], 'Mercado Boa Compra');
      final line = (entry['paymentLines']! as List).single as Map;
      expect(line['paymentMethodId'], 'debit');
    });

    test('lançamento dividido não troca valor pela conversa: o motivo volta '
        'ao modelo, e nada muda', () async {
      final client = ToolChatClient([
        _calls('corrigir_lancamento', {'id': 'split', 'valor_centavos': 100}),
        _text('Esse se corrige no app.'),
      ]);
      final (server, token) = await _server(client);
      await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(id: 'split'),
        token: token,
      );

      await _ask(server, token);
      final entries = await _entries(server, token);
      final split = entries.firstWhere((entry) => entry['id'] == 'split');

      expect(split['amountCents'], 8600);
    });
  });
}
