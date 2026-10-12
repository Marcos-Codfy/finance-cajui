import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/assistant/server_finances.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

/// O salário da Ana como o extrato o leu: R$ 2.000,00, em vez dos R$ 1.800,00
/// esperados.
const Map<String, Object?> _salary = {
  'id': 'salario-lido',
  'sourceId': 'ana',
  'tender': 'cash',
  'amountCents': 200000,
  'receivedOn': '2026-09-05',
};

/// O fato "recebimento desfeito" para [receiptId].
Map<String, Object?> _undo(String receiptId) => {
  'id': 'income-cancel-$receiptId',
  'type': DeviceFact.incomeCancelled,
  'payload': IncomeCancellationCodec.encode((
    receiptId: receiptId,
    on: LocalDate(2026, 9, 20),
  )),
};

/// O que a Juju recebeu de contexto na última pergunta.
String _context(ToolChatClient client) =>
    client.conversations.last.map((message) => message.content).join('\n');

Future<void> _post(TestApp server, String token, String path, Object body) =>
    server.call('POST', path, body: body, token: token);

void main() {
  group('RN-1120 · o recebimento desfeito sai dos números do servidor', () {
    test('a Juju volta a falar com a renda esperada depois de desfeito o '
        'salário lido', () async {
      final client = ToolChatClient([jujuText('Certo.'), jujuText('Certo.')]);
      final (server, token) = await jujuServer(client);
      await _post(server, token, '/v1/facts', houseBudgetFact());
      await _post(server, token, '/v1/income', _salary);

      await askJuju(server, token, 'Quanto entra este mês?');
      // 2.000 lidos da Ana mais 1.500 esperados do Beto.
      expect(_context(client), contains('"cents":350000'));

      await _post(server, token, '/v1/facts', _undo('salario-lido'));
      await askJuju(server, token, 'E agora?');

      // De volta ao esperado: 1.800 da Ana e 1.500 do Beto.
      expect(_context(client), contains('"cents":330000'));
      expect(_context(client), isNot(contains('"cents":350000')));
    });

    test('o desfeito some da lista que os celulares descem, e o fato fica '
        'para o outro celular desfazer também', () async {
      final (server, token) = await jujuServer(ToolChatClient(const []));
      await _post(server, token, '/v1/income', _salary);
      await _post(server, token, '/v1/facts', _undo('salario-lido'));

      final (_, income) = await server.call('GET', '/v1/income', token: token);
      final (_, facts) = await server.call('GET', '/v1/facts', token: token);

      expect(income['receipts'], isEmpty);
      expect(
        (facts['facts']! as List).cast<Map<String, Object?>>().single['type'],
        DeviceFact.incomeCancelled,
      );
    });

    test('o desfeito que chega antes do recebimento ganha dele: o celular '
        'sobe os fatos antes do que entrou', () async {
      final (server, token) = await jujuServer(ToolChatClient(const []));
      await _post(server, token, '/v1/facts', _undo('salario-lido'));
      await _post(server, token, '/v1/income', _salary);

      final state = LedgerState(server.store.events);

      expect(state.receipts, isEmpty);
      expect(state.receivedIn(const BudgetMonth(2026, 9)).cash, Money.zero);
      expect(ServerFinances.of(state).receipts, isEmpty);
    });

    test('mandar de novo o recebimento desfeito não o traz de volta', () async {
      final (server, token) = await jujuServer(ToolChatClient(const []));
      await _post(server, token, '/v1/income', _salary);
      await _post(server, token, '/v1/facts', _undo('salario-lido'));
      await _post(server, token, '/v1/income', _salary);

      final (_, income) = await server.call('GET', '/v1/income', token: token);

      expect(income['receipts'], isEmpty);
    });

    test('o vale desfeito sai do saldo', () async {
      final (server, token) = await jujuServer(ToolChatClient(const []));
      await _post(server, token, '/v1/income', {
        ..._salary,
        'tender': 'mealVoucher',
        'sourceId': null,
      });
      await _post(server, token, '/v1/facts', _undo('salario-lido'));

      final (_, income) = await server.call('GET', '/v1/income', token: token);

      // O mercado de R$ 86,00 pagou R$ 30,00 em vale: sem o crédito, o
      // saldo fica em zero, com o que passou a descoberto.
      expect(income['voucherBalanceCents'], 0);
    });
  });
}
