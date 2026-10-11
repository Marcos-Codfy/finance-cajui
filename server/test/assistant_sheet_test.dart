import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/sample_bodies.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

/// O servidor de sempre, com a categoria Farmácia também.
Future<(TestApp, String)> _withPharmacy(ToolChatClient client) async {
  final (server, token) = await jujuServer(client);
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
      final client = ToolChatClient([jujuText('Certo.')]);
      final (server, token) = await jujuServer(client);
      await server.call(
        'POST',
        '/v1/facts',
        body: houseBudgetFact(),
        token: token,
      );

      await askJuju(server, token, 'Como está o mês?');
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
      // O vale cobre os 86 do mercado: 86 ÷ 4 = 21,50 do limite é vale.
      expect(sent, contains('Parte do limite da semana que é vale'));
      expect(sent, contains('"cents":2150'));
    });

    test('RN-1032 · a dívida cadastrada no aparelho vira "quanto ainda '
        'devo", pelo calendário', () async {
      final client = ToolChatClient([jujuText('Certo.')]);
      final (server, token) = await jujuServer(client);
      await server.call('POST', '/v1/facts', body: houseDebtFact, token: token);

      await askJuju(server, token, 'Quanto eu devo?');
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
        jujuCall('mudar_categoria', {'id': 'e2', 'categoria_id': 'health'}),
        jujuText('Troquei para Farmácia.'),
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

      await askJuju(server, token, 'os 45 de sábado foram farmácia');

      expect(await _categoryOf(server, token, 'e2'), 'health');
      expect(_revisions(server), hasLength(1));
    });

    test('RN-111 · o que o vale pagou não vira farmácia: a Juju ouve o '
        'motivo, e nada é gravado', () async {
      final client = ToolChatClient([
        jujuCall('mudar_categoria', {'id': 'e1', 'categoria_id': 'health'}),
        jujuText('Não deu: o vale só paga comida.'),
      ]);
      final (server, token) = await _withPharmacy(client);

      await askJuju(server, token, 'o mercado foi farmácia');

      expect(await _categoryOf(server, token, 'e1'), 'groceries');
      expect(_revisions(server), isEmpty);
      final reply = client.conversations.last.last.content;
      expect(reply, contains('vale alimentação só paga'));
    });
  });
}
