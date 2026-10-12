import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/ai_statement_reader.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/app.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fixed_clock.dart';
import 'sample_bodies.dart';
import 'test_app.dart';
import 'tool_chat_client.dart';

/// Uma página de extrato de setembro de 2026, com as linhas como o celular
/// as manda. Hoje, no cenário, é 20/09/2026.
const statementLines = [
  'EXTRATO CONTA CORRENTE - SETEMBRO 2026',
  '03/09 PADARIA BOA VISTA 12,50',
  '05/09 PIX ENVIADO JOAO P SILVA 150,00',
  '08/09 NETFLIX.COM 55,90',
  '10/09 PAGAMENTO DE FATURA 1.500,00',
  '12/09 PIX RECEBIDO MARIA DE SOUZA LIMA 320,00',
];

/// A rota de leitura por página.
const readPartPath = '/v1/statements/read-part';

/// O servidor inteiro, com o leitor de extrato sobre o [client] de mentira
/// — ou sem leitor, sem [client] — e a categoria Mercado cadastrada.
Future<App> statementServer(ToolChatClient? client) async {
  final data = Directory.systemTemp.createTempSync('cajui-extrato-');
  addTearDown(() => data.deleteSync(recursive: true));
  final store = await FileEventStore.open(
    data,
    AesGcmRecordCipher(List.generate(32, (i) => i)),
  );
  final app = App(
    store: store,
    clock: const FixedClock(),
    log: (_) {},
    sessions: SessionBook(),
    householdKey: HouseholdKey(TestApp.key),
    statementReader: client == null
        ? null
        : AiStatementReader(
            client: client,
            budget: TokenBudget(store, monthlyLimit: 1000000),
            breaker: CircuitBreaker(),
          ),
  );
  await postTo(app, '/v1/categories', groceriesBody);
  return app;
}

/// Um POST com a chave da casa — ou com [token] — e a resposta lida.
Future<(int, Map<String, Object?>)> postTo(
  App app,
  String path,
  Object body, {
  String token = TestApp.key,
}) async {
  final response = await app.handler(
    Request(
      'POST',
      Uri.parse('http://localhost$path'),
      body: jsonEncode(body),
      headers: {'authorization': 'Bearer $token'},
    ),
  );
  final text = await response.readAsString();
  final json = text.isEmpty ? <String, Object?>{} : jsonDecode(text);
  return (response.statusCode, json as Map<String, Object?>);
}

/// Lê a página [lines] e devolve o status e a resposta já lida.
Future<(int, StatementPageReply)> readPage(
  App app, {
  List<String> lines = statementLines,
  Map<String, String> examples = const {},
}) async {
  final (status, body) = await postTo(
    app,
    readPartPath,
    StatementPageRequest(
      lines: lines,
      page: 1,
      pageCount: 2,
      examples: examples,
    ).toJson(),
  );
  return (
    status,
    StatementPageReply.fromJson(body, knowsCategory: (_) => true),
  );
}

/// A resposta inteira da IA, com as movimentações [lines].
ChatReply aiPage(List<Map<String, Object?>> lines, {String? period}) =>
    ChatReply(
      content: jsonEncode({'period': period, 'lines': lines}),
      promptTokens: 1500,
      completionTokens: 400,
    );

/// Uma resposta cortada pelo teto: o JSON de [lines] e o começo de mais
/// uma movimentação, que não fechou.
ChatReply aiCut(List<Map<String, Object?>> lines) {
  final whole = jsonEncode({'period': '2026-09', 'lines': lines});
  return ChatReply(
    content: '${whole.substring(0, whole.length - 2)},{"line": 6, "day": 1',
    promptTokens: 1500,
    completionTokens: 4000,
    truncated: true,
  );
}

/// Uma movimentação de setembro como a IA a escreve.
Map<String, Object?> aiMove(
  int line,
  int day,
  int cents, {
  String description = 'Padaria Boa Vista',
  String? categoryId,
}) => {
  'line': line,
  'day': day,
  'month': 9,
  'year': null,
  'description': description,
  'amountCents': cents,
  'kind': 'expense',
  'categoryId': categoryId,
  'confidence': 'high',
  'paymentKind': null,
};

/// O que a IA recebeu na pergunta [index].
String askedOf(ToolChatClient client, [int index = 0]) => client
    .conversations[index]
    .lastWhere((message) => message.role == ChatRole.user)
    .content;
