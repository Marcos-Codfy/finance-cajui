import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:server/src/assistant/assistant_service.dart';

import 'sample_bodies.dart';
import 'test_app.dart';
import 'tool_chat_client.dart';

/// A casa inventada dos testes da Juju com a planilha: os fatos que o
/// aparelho manda e o servidor com o mercado de R$ 86,00 já lançado.
/// Uma resposta de texto da IA.
ChatReply jujuText(String content) =>
    ChatReply(content: content, promptTokens: 900, completionTokens: 60);

/// Um pedido de ferramenta da IA.
ChatReply jujuCall(String name, Map<String, Object?> arguments) => ChatReply(
  content: '',
  toolCalls: [ToolCall(id: 'c1', name: name, arguments: arguments)],
  promptTokens: 900,
  completionTokens: 30,
);

/// Um salário da casa inventada.
IncomeSource houseSalary(String id, int cents) => IncomeSource(
  id: id,
  name: id,
  tender: Tender.cash,
  expectedAmount: Money.fromCents(cents),
  expectedDay: 5,
);

/// A planilha de uma casa inventada, como o aparelho a manda: dois
/// salários (R$ 1.800 e R$ 1.500), vale de R$ 500, dízimo de 10% e aluguel
/// de R$ 1.000.
Map<String, Object?> houseBudgetFact() => {
  'id': 'budget-2026-09-01',
  'type': DeviceFact.budgetDefined,
  'payload': BudgetPlanCodec.encode(
    BudgetPlan(
      salaries: [houseSalary('ana', 180000), houseSalary('beto', 150000)],
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
const Map<String, Object?> houseDebtFact = {
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
Future<(TestApp, String)> jujuServer(ToolChatClient client) async {
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

/// Uma pergunta à Juju.
Future<void> askJuju(TestApp server, String token, String message) =>
    server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': message},
      token: token,
    );
