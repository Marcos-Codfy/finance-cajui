import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'support/statement_server.dart';
import 'support/tool_chat_client.dart';

/// O print da lista de um app de banco, fictício: a data é cabeçalho
/// ("08 de setembro de 2026"), cada movimento ocupa três linhas — o tipo da
/// operação, o nome e o valor — e há uma linha de saldo no meio.
const List<String> _appList = [
  '08 de setembro de 2026',
  'Pagamento de pix qr code',
  'Mercadinho do Bairro',
  r'- R$ 16,38',
  'Pix recebido',
  'Loja de Teste',
  r'+ R$ 40,00',
  r'Saldo do dia R$ 500,00',
];

void main() {
  group('BL-118 · o print da lista de um app de banco', () {
    test('a data do cabeçalho "08 de setembro" vale para as linhas de baixo: '
        'sem a foto, a lista inteira caía', () async {
      final client = ToolChatClient([
        aiPage([
          {...aiMove(4, 8, 1638, description: 'Mercadinho do Bairro')},
          {
            ...aiMove(7, 8, 4000, description: 'Loja de Teste'),
            'kind': 'income',
          },
        ]),
      ]);

      final (status, reply) = await readPage(
        await statementServer(client),
        lines: _appList,
      );

      expect(status, 200);
      final [paid, received] = reply.movements;
      expect(paid.amount, const Money.fromCents(1638));
      expect(paid.kind, StatementLineKind.expense);
      expect(received.amount, const Money.fromCents(4000));
      expect(received.kind, StatementLineKind.income);
    });

    test(
      'o pedido ensina a lista de três linhas e deixa o saldo de fora',
      () async {
        final client = ToolChatClient([aiPage(const [])]);

        await readPage(await statementServer(client), lines: _appList);
        final system = client.conversations.single.first.content;

        expect(system, contains('08 de outubro de 2026'));
        expect(system, contains('o tipo da operação'));
        expect(system, contains('"Saldo do dia"'));
        expect(system, contains('Pix recebido'));
      },
    );
  });
}
