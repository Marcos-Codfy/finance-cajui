import 'package:api_contract/api_contract.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// As rotas do que **entrou**: recebimentos e acertos de saldo do vale.
///
/// Ficam fora das rotas de lançamento de propósito, porque recebimento não é
/// lançamento (RN-132): não tem categoria, não entra em bloco de despesa e
/// nunca se compensa com um gasto. Sem elas, o servidor sabia quanto saiu e
/// não sabia quanto entrou — e a consulta pela web mostrava o vale zerado.
final class IncomeRoutes {
  /// Cria as rotas sobre o registro [store] e o estado [state].
  new({required this.store, required this.state});

  /// O registro de eventos.
  final EventStore store;

  /// A projeção em memória.
  final LedgerState state;

  /// O roteador, montado em `/v1`.
  Router get router => Router()
    ..get('/income', _list)
    ..post('/income', _receive)
    ..post('/voucher/adjustments', _adjust);

  /// Tudo junto numa resposta só: quem lê quer o saldo, e o saldo depende
  /// dos dois. Duas viagens para montar um número é uma a mais.
  Response _list(Request request) => Responses.json({
    'receipts': [
      for (final receipt in state.receipts.values) IncomeCodec.encode(receipt),
    ],
    'voucherAdjustments': [...state.voucherAdjustments.values],
    'voucherBalanceCents': state.voucherBalance.cents,
  });

  Future<Response> _receive(Request request) async {
    final receipt = IncomeCodec.read(await JsonBody.read(request));
    final event = await store.append(
      id: 'income-${receipt.id}',
      type: LedgerState.incomeReceived,
      payload: IncomeCodec.encode(receipt),
    );
    state.apply(event);
    return Responses.json({'id': receipt.id, 'seq': event.seq}, status: 201);
  }

  /// Acertar o saldo não é renda nem despesa (RN-123): é o app admitindo que
  /// o saldo de verdade é o do cartão do vale, e não o que ele calculou.
  Future<Response> _adjust(Request request) async {
    final payload = IncomeCodec.readAdjustment(await JsonBody.read(request));
    final event = await store.append(
      id: 'voucher-${payload['id']}',
      type: LedgerState.voucherAdjusted,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'id': payload['id'], 'seq': event.seq}, status: 201);
  }
}
