import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

/// O servidor de sempre, com a categoria das parcelas de dívida e o
/// empréstimo de 12 × R$ 212,00 — seis ainda por pagar, R$ 1.272,00.
Future<(TestApp, String)> _withDebt(ToolChatClient client) async {
  final (server, token) = await jujuServer(client);
  await server.call(
    'POST',
    '/v1/categories',
    body: const {
      'id': 'debt-installment',
      'name': 'Parcela de dívida',
      'block': 'debt',
      'groupId': 'debt',
    },
    token: token,
  );
  await server.call('POST', '/v1/facts', body: houseDebtFact, token: token);
  return (server, token);
}

/// Os lançamentos e as versões de dívida no registro — o resto (o uso de
/// tokens de cada pergunta) não importa aqui.
int _written(TestApp server) => server.store.events
    .where(
      (event) =>
          event.type == 'entry.created' || event.type == DeviceFact.debtDefined,
    )
    .length;

String _said(ToolChatClient client, int conversation) => client
    .conversations[conversation]
    .map((message) => message.content)
    .join('\n');

void main() {
  group('BL-117 · a Juju abate dívida', () {
    test('"paguei 500 do empréstimo": o pagamento vira lançamento do bloco '
        'de dívidas e o saldo cai junto', () async {
      final client = ToolChatClient([
        jujuCall('abater_divida', {
          'divida_id': 'debt-1',
          'valor_centavos': 50000,
        }),
        jujuText(r'Abati R$ 500,00.'),
        jujuText(r'Ainda deve R$ 772,00.'),
      ]);
      final (server, token) = await _withDebt(client);

      final (_, body) = await server.call(
        'POST',
        '/v1/assistant/ask',
        body: {'message': 'paguei 500 do empréstimo'},
        token: token,
      );
      // O resultado da ferramenta, que o modelo lê: 1.272 − 500 = 772.
      expect(_said(client, 1), contains('"ainda_deve_centavos":77200'));
      expect(_said(client, 1), contains('Banco do bairro · abatimento'));
      // O celular recebe a ação que sabe devolver o saldo no Desfazer.
      expect(body['actions'], [containsPair('kind', 'paidDown')]);
      expect(
        (body['actions']! as List).single,
        containsPair('debtId', 'debt-1'),
      );

      await askJuju(server, token, 'quanto eu devo?');
      // A pergunta seguinte já sai com o saldo novo no contexto.
      expect(_said(client, 2), contains('"cents":77200'));
      expect(_said(client, 2), isNot(contains('"cents":127200')));
    });

    test('valor acima do que se deve é recusado, e nada é gravado', () async {
      final client = ToolChatClient([
        jujuCall('abater_divida', {
          'divida_id': 'debt-1',
          'valor_centavos': 200000,
        }),
        jujuText('Não deu.'),
      ]);
      final (server, token) = await _withDebt(client);
      final before = _written(server);

      await askJuju(server, token, 'paguei 2000 do empréstimo');

      expect(_said(client, 1), contains('passa do que ainda se deve'));
      expect(_written(server), before);
    });

    test('dívida que não existe é recusada pelo nome do campo', () async {
      final client = ToolChatClient([
        jujuCall('abater_divida', {
          'divida_id': 'nao-existe',
          'valor_centavos': 1000,
        }),
        jujuText('Não achei.'),
      ]);
      final (server, token) = await _withDebt(client);

      await askJuju(server, token, 'abate 10 da dívida');

      expect(_said(client, 1), contains('dívida não encontrada'));
    });

    test('o cadastro da Juju lista as dívidas com o saldo de hoje', () async {
      final client = ToolChatClient([jujuText('Certo.')]);
      final (server, token) = await _withDebt(client);

      await askJuju(server, token, 'o que eu devo?');

      expect(_said(client, 0), contains('"credor":"Banco do bairro"'));
      expect(_said(client, 0), contains('"ainda_deve_centavos":127200'));
    });
  });
}
