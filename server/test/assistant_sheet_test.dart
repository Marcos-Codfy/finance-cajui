import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_reply.dart';
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

ChatReply _call(String name, Map<String, Object?> arguments) => ChatReply(
  content: '',
  toolCalls: [ToolCall(id: 'c1', name: name, arguments: arguments)],
  promptTokens: 900,
  completionTokens: 30,
);

IncomeSource _salary(String id, int cents) => IncomeSource(
  id: id,
  name: id,
  tender: Tender.cash,
  expectedAmount: Money.fromCents(cents),
  expectedDay: 5,
);

/// A planilha de uma casa inventada, como o aparelho a manda: dois
/// salários (R$ 1.800 e R$ 1.500), vale de R$ 500, dízimo de 10% e aluguel
/// de R$ 1.000.
Map<String, Object?> _budgetFact() => {
  'id': 'budget-2026-09-01',
  'type': DeviceFact.budgetDefined,
  'payload': BudgetPlanCodec.encode(
    BudgetPlan(
      salaries: [_salary('ana', 180000), _salary('beto', 150000)],
      voucher: const Money.fromCents(50000),
      titheBasisPoints: 1000,
      lines: [
        BudgetLine.create(
          id: 'aluguel',
          name: 'Aluguel',
          amount: const Money.fromCents(100000),
          group: LineGroup.fixedBill,
          categoryId: 'housing',
        ).valueOrNull!,
      ],
      definedAt: DateTime.utc(2026, 9),
    ),
  ),
};

/// Um empréstimo de 12 parcelas de R$ 212,00 desde abril, com 5 pagas.
const Map<String, Object?> _debtFact = {
  'id': 'fato-divida',
  'type': DeviceFact.debtDefined,
  'payload': {
    'id': 'debt-1',
    'creditor': 'Banco do bairro',
    'kind': 'loan',
    'installmentCents': 21200,
    'totalInstallments': 12,
    'paidInstallments': 5,
    'dueDay': 10,
    'firstMonth': '2026-04',
    'cardId': null,
    'payoffCents': null,
    'payoffQuotedOn': null,
  },
};

/// Sobe o servidor com o Mercado e o mercado de R$ 86,00 já lançados.
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

Future<void> _ask(TestApp server, String token, String message) => server.call(
  'POST',
  '/v1/assistant/ask',
  body: {'message': message},
  token: token,
);

/// O servidor de sempre, com a categoria Farmácia também.
Future<(TestApp, String)> _withPharmacy(ToolChatClient client) async {
  final (server, token) = await _server(client);
  await server.call(
    'POST',
    '/v1/categories',
    body: const {
      'id': 'health',
      'name': 'Farmácia',
      'block': 'variable',
      'groupId': 'health',
      'voucherEligible': false,
    },
    token: token,
  );
  return (server, token);
}

Future<Object?> _categoryOf(TestApp server, String token, String id) async {
  final (_, body) = await server.call('GET', '/v1/entries', token: token);
  final entries = (body['entries']! as List).cast<Map<String, Object?>>();
  return entries.singleWhere((entry) => entry['id'] == id)['categoryId'];
}

Iterable<Object> _revisions(TestApp server) =>
    server.store.events.where((event) => event.type == 'entry.revised');

void main() {
  group('ADR-023 · a Juju fala com os números da planilha', () {
    test('RN-1010 · o plano que o aparelho salvou chega ao contexto: o que '
        'entra, o dízimo, o vale e a sobra', () async {
      final client = ToolChatClient([_text('Certo.')]);
      final (server, token) = await _server(client);
      await server.call('POST', '/v1/facts', body: _budgetFact(), token: token);

      await _ask(server, token, 'Como está o mês?');
      final sent = client.conversations.single
          .map((message) => message.content)
          .join('\n');

      expect(sent, contains('O que entra no mês, em dinheiro'));
      expect(sent, contains('"cents":330000'));
      expect(sent, contains('Dízimo do mês'));
      expect(sent, contains('"cents":33000'));
      expect(sent, contains('Vale do mês (só compra comida)'));
      // Saem 1.000 de aluguel, 86 de mercado e 330 de dízimo; o vale paga os
      // 86 do mercado. Do bolso, 1.330: sobram 1.970.
      expect(sent, contains('"cents":197000'));
      // (3.300 − 1.000 − 330 + 86) ÷ 4 = 514.
      expect(sent, contains('Pode gastar por semana'));
      expect(sent, contains('"cents":51400'));
    });

    test('RN-1032 · a dívida cadastrada no aparelho vira "quanto ainda '
        'devo", pelo calendário', () async {
      final client = ToolChatClient([_text('Certo.')]);
      final (server, token) = await _server(client);
      await server.call('POST', '/v1/facts', body: _debtFact, token: token);

      await _ask(server, token, 'Quanto eu devo?');
      final sent = client.conversations.single
          .map((message) => message.content)
          .join('\n');

      // De abril a setembro venceram seis; faltam seis de R$ 212,00.
      expect(sent, contains('Quanto ainda devo'));
      expect(sent, contains('"cents":127200'));
    });
  });

  group('a Juju com mais autonomia', () {
    test('"isso foi farmácia" troca a categoria, e a correção fica no '
        'registro (RN-208)', () async {
      final client = ToolChatClient([
        _call('mudar_categoria', {'id': 'e2', 'categoria_id': 'health'}),
        _text('Troquei para Farmácia.'),
      ]);
      final (server, token) = await _withPharmacy(client);
      await server.call(
        'POST',
        '/v1/entries',
        body: entryBody(
          id: 'e2',
          cents: 4500,
          lines: [
            {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 4500},
          ],
        ),
        token: token,
      );

      await _ask(server, token, 'os 45 de sábado foram farmácia');

      expect(await _categoryOf(server, token, 'e2'), 'health');
      expect(_revisions(server), hasLength(1));
    });

    test('RN-111 · o que o vale pagou não vira farmácia: a Juju ouve o '
        'motivo, e nada é gravado', () async {
      final client = ToolChatClient([
        _call('mudar_categoria', {'id': 'e1', 'categoria_id': 'health'}),
        _text('Não deu: o vale só paga comida.'),
      ]);
      final (server, token) = await _withPharmacy(client);

      await _ask(server, token, 'o mercado foi farmácia');

      expect(await _categoryOf(server, token, 'e1'), 'groceries');
      expect(_revisions(server), isEmpty);
      final reply = client.conversations.last.last.content;
      expect(reply, contains('vale alimentação só paga'));
    });

    test('RN-758 · com dois salários na casa, "recebi 1.500" fica no salário '
        'de quem recebe 1.500', () async {
      final client = ToolChatClient([
        _call('registrar_renda', {
          'valor_centavos': 150000,
          'tipo': 'salario',
          'data': '2026-09-05',
        }),
        _text('Registrei.'),
      ]);
      final (server, token) = await _server(client);
      await server.call('POST', '/v1/facts', body: _budgetFact(), token: token);

      await _ask(server, token, 'recebi meu salário de 1500');
      final (_, income) = await server.call('GET', '/v1/income', token: token);
      final receipt = (income['receipts']! as List).single as Map;

      expect(receipt['sourceId'], 'beto');
    });
  });
}
