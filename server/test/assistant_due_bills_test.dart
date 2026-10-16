import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/sample_bodies.dart';
import 'support/tool_chat_client.dart';

/// Tudo o que a IA leu na conversa [index].
String _said(ToolChatClient client, int index) =>
    client.conversations[index].map((message) => message.content).join('\n');

void main() {
  group('a Juju sabe o que falta pagar', () {
    test('contas_a_pagar traz a conta fixa sem pagamento, com a categoria '
        'que paga ela', () async {
      final client = ToolChatClient([
        jujuCall('contas_a_pagar', const {}),
        jujuText('Falta o aluguel.'),
      ]);
      final (server, token) = await jujuServer(client);
      await server.call('POST', '/v1/plan', body: planBody(), token: token);

      await askJuju(server, token, 'o que falta pagar?');
      final result = _said(client, 1);

      expect(result, contains('"conta":"Aluguel"'));
      expect(result, contains('"categoria_id":"housing"'));
      expect(result, contains('"valor_centavos":120000'));
    });

    test('sem planilha, a lista vem vazia — nada inventado', () async {
      final client = ToolChatClient([
        jujuCall('contas_a_pagar', const {}),
        jujuText('Nada.'),
      ]);
      final (server, token) = await jujuServer(client);

      await askJuju(server, token, 'o que falta pagar?');

      expect(_said(client, 1), contains('"contas":[]'));
    });

    test('RN-912 · a lista não vai no cadastro de toda pergunta: só quando '
        'a Juju pede', () async {
      final client = ToolChatClient([jujuText('Certo.')]);
      final (server, token) = await jujuServer(client);
      await server.call('POST', '/v1/plan', body: planBody(), token: token);

      await askJuju(server, token, 'quanto gastei?');

      expect(_said(client, 0), isNot(contains('"conta":"Aluguel"')));
      expect(_said(client, 0), contains('chame contas_a_pagar'));
    });
  });
}
