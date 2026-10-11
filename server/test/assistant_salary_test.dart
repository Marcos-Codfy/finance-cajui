import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/tool_chat_client.dart';

void main() {
  group('RN-758 RN-1006 · de quem é o salário que a Juju registra', () {
    test('RN-758 · com dois salários na casa, "recebi 1.500" fica no salário '
        'de quem recebe 1.500', () async {
      final client = ToolChatClient([
        jujuCall('registrar_renda', {
          'valor_centavos': 150000,
          'tipo': 'salario',
          'data': '2026-09-05',
        }),
        jujuText('Registrei.'),
      ]);
      final (server, token) = await jujuServer(client);
      await server.call(
        'POST',
        '/v1/facts',
        body: houseBudgetFact(),
        token: token,
      );

      await askJuju(server, token, 'recebi meu salário de 1500');
      final (_, income) = await server.call('GET', '/v1/income', token: token);
      final receipt = (income['receipts']! as List).single as Map;

      expect(receipt['sourceId'], 'beto');
    });

    test('RN-1006 · salário fora do esperado vai para o que ainda não foi '
        'recebido, nunca para o já recebido', () async {
      final client = ToolChatClient([
        jujuCall('registrar_renda', {
          'valor_centavos': 180000,
          'tipo': 'salario',
          'data': '2026-09-05',
        }),
        jujuCall('registrar_renda', {
          'valor_centavos': 170000,
          'tipo': 'salario',
          'data': '2026-09-06',
        }),
        jujuText('Registrei.'),
      ]);
      final (server, token) = await jujuServer(client);
      await server.call(
        'POST',
        '/v1/facts',
        body: houseBudgetFact(),
        token: token,
      );

      await askJuju(server, token, 'caíram os dois salários');
      final (_, income) = await server.call('GET', '/v1/income', token: token);
      final sources = [
        for (final receipt
            in (income['receipts']! as List).cast<Map<String, Object?>>())
          receipt['sourceId'],
      ];

      // 1.700 não parece o do Beto (1.500 + 13%): fica com ele por ser o
      // único ainda aberto, e não volta para a Ana.
      expect(sources, ['ana', 'beto']);
    });

    test('dois salários abertos e nenhum parecido: a ferramenta pergunta de '
        'quem é, e nada é gravado', () async {
      final client = ToolChatClient([
        jujuCall('registrar_renda', {
          'valor_centavos': 99900,
          'tipo': 'salario',
        }),
        jujuText('De quem é esse salário?'),
      ]);
      final (server, token) = await jujuServer(client);
      await server.call(
        'POST',
        '/v1/facts',
        body: houseBudgetFact(),
        token: token,
      );

      await askJuju(server, token, 'caiu um salário de 999');
      final (_, income) = await server.call('GET', '/v1/income', token: token);
      final refusal = client.conversations.last.last.content;

      expect(income['receipts'], isEmpty);
      expect(refusal, contains('salario_id'));
    });

    test(
      'a Juju diz de quem é com salario_id, e o recebido entra nele',
      () async {
        final client = ToolChatClient([
          jujuCall('registrar_renda', {
            'valor_centavos': 99900,
            'tipo': 'salario',
            'salario_id': 'beto',
          }),
          jujuText('Registrei no salário do Beto.'),
        ]);
        final (server, token) = await jujuServer(client);
        await server.call(
          'POST',
          '/v1/facts',
          body: houseBudgetFact(),
          token: token,
        );

        await askJuju(server, token, 'caiu o salário do beto, 999');
        final (_, income) = await server.call(
          'GET',
          '/v1/income',
          token: token,
        );
        final receipt = (income['receipts']! as List).single as Map;

        expect(receipt['sourceId'], 'beto');
      },
    );
  });
}
