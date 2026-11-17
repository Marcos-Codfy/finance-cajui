import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

ChatReply _reply(String content, [List<ToolCall> calls = const []]) =>
    ChatReply(
      content: content,
      toolCalls: calls,
      promptTokens: 900,
      completionTokens: 30,
    );

/// RN-1120 pela Juju: uma entrada de dinheiro registrada errada também sai
/// por `cancelar_lancamento`. Antes ela ficava na renda do mês sem caminho
/// de volta fora do "Desfazer tudo" do extrato.
void main() {
  test('o recebimento sai da renda, nada é apagado, e o id errado é '
      'recusado', () async {
    final client = ToolChatClient([
      _reply('', [
        const ToolCall(
          id: 'c1',
          name: 'cancelar_lancamento',
          arguments: {'id': 'r1'},
        ),
      ]),
      _reply('Tirei a entrada.'),
      _reply('', [
        const ToolCall(
          id: 'c2',
          name: 'cancelar_lancamento',
          arguments: {'id': 'r1'},
        ),
      ]),
      _reply('Essa entrada já tinha saído.'),
    ]);
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
      '/v1/income',
      body: {
        'id': 'r1',
        'sourceId': null,
        'tender': 'cash',
        'amountCents': 70000,
        'receivedOn': '2026-09-03',
      },
      token: token,
    );

    await server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': 'essa entrada de 700 está errada'},
      token: token,
    );
    final (_, income) = await server.call('GET', '/v1/income', token: token);
    expect(income['receipts'], isEmpty);

    // De novo: o id não é mais de nada vivo, e a ferramenta diz isso.
    await server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': 'tira de novo'},
      token: token,
    );
    final last = client.conversations.last.last.content;
    expect(last, contains('não há lançamento vivo'));
  });
}
