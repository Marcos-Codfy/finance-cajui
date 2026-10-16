import 'dart:convert';

import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/assistant/assistant_tool_catalog.dart';
import 'package:server/src/assistant/assistant_tools.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/sample_bodies.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

void main() {
  test('RN-906 · a sessão da web chega à rota da conversa, e continua sem '
      'poder lançar', () async {
    final server = await TestApp.start();
    final device = server.token();
    final web = server.token(scope: SessionScope.webReadOnly);
    await server.call(
      'POST',
      '/v1/categories',
      body: groceriesBody,
      token: device,
    );

    final (chat, chatBody) = await server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': 'Oi'},
      token: web,
    );
    final (write, writeBody) = await server.call(
      'POST',
      '/v1/entries',
      body: entryBody(),
      token: web,
    );

    // Este servidor de teste não tem a credencial da IA, então a conversa
    // responde "fora do ar" — o que prova que a sessão da web **passou** pela
    // autenticação. Lançar, não: é barrado antes de chegar à rota (T-12).
    expect(chat, 503);
    expect(errorOf(chatBody)['code'], 'E-AI-01');
    expect(write, 403);
    expect(errorOf(writeBody)['code'], 'E-AUTH-03');
  });

  test('RN-906 · na sessão só de leitura, a Juju conversa e consulta, mas '
      'não lança nem pelo pedido de ferramenta', () async {
    final client = ToolChatClient([
      jujuCall(AssistantToolCatalog.recordExpense, {
        'descricao': 'Mercado',
        'valor_centavos': 8000,
        'categoria_id': 'groceries',
      }),
      jujuText('Isso se faz no celular.'),
    ]);
    final server = await TestApp.start(
      assistant: (store) => AssistantService(
        client: client,
        budget: TokenBudget(store, monthlyLimit: 1000000),
        breaker: CircuitBreaker(),
      ),
    );
    final device = server.token();
    await server.call(
      'POST',
      '/v1/categories',
      body: groceriesBody,
      token: device,
    );
    final web = server.token(scope: SessionScope.webReadOnly);

    final (status, _) = await server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': 'lança 80 de mercado'},
      token: web,
    );
    final (_, entries) = await server.call('GET', '/v1/entries', token: device);

    expect(status, 200);
    expect(entries['entries'], isEmpty);
    expect(
      [for (final tool in client.offered.first) tool.name],
      [AssistantToolCatalog.listEntries, AssistantToolCatalog.dueBills],
    );
    final result = client.conversations[1].lastWhere(
      (message) => message.role == ChatRole.tool,
    );
    expect(jsonDecode(result.content), {
      'erro': AssistantTools.readOnlyRefusal,
    });
    expect(client.conversations.first[1].content, contains('só lê'));
  });
}
