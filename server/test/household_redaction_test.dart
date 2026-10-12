import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

/// O fato que o celular manda com os nomes da casa (RN-1070).
Map<String, Object?> _names(String id, List<String> names, DateTime at) => {
  'id': id,
  'type': DeviceFact.householdNamed,
  'payload': HouseholdCodec.encode(HouseholdNames(names: names, definedAt: at)),
};

/// A pergunta como saiu para a IA.
String _question(ToolChatClient client) => client.conversations.first
    .lastWhere((message) => message.role == ChatRole.user)
    .content;

Future<void> _send(TestApp server, String token, Map<String, Object?> fact) =>
    server.call('POST', '/v1/facts', body: fact, token: token);

void main() {
  group('RN-732 · o nome de alguém da casa não vai para a IA (BL-093)', () {
    test('a frase ditada sai com o nome mascarado', () async {
      final client = ToolChatClient([jujuText('Certo.')]);
      final (server, token) = await jujuServer(client);
      await _send(
        server,
        token,
        _names('casa-1', ['Bianca Souza Lima'], DateTime.utc(2026, 10)),
      );

      await askJuju(server, token, 'mandei 500 para Bianca Souza Lima');

      expect(_question(client), isNot(contains('Bianca Souza Lima')));
      expect(_question(client), contains('500'));
    });

    test('vale a lista mais nova pelo carimbo, como nos celulares', () async {
      final client = ToolChatClient([jujuText('Certo.')]);
      final (server, token) = await jujuServer(client);
      await _send(
        server,
        token,
        _names('casa-2', ['Bianca Souza Lima'], DateTime.utc(2026, 10, 5)),
      );
      // Chegou depois, mas foi decidida antes: não apaga a mais nova.
      await _send(
        server,
        token,
        _names('casa-1', ['Carlos Pereira'], DateTime.utc(2026, 10)),
      );

      await askJuju(server, token, 'Bianca Souza Lima e Carlos Pereira');

      expect(_question(client), isNot(contains('Bianca Souza Lima')));
      expect(_question(client), contains('Carlos Pereira'));
    });
  });
}
