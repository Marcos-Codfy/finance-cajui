import 'package:api_contract/api_contract.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// As rotas dos fatos que o servidor **guarda e devolve sem fazer conta**:
/// fatura paga, dívida, parcela de dívida paga e mês fechado (ADR-019).
///
/// Existem para os dois celulares mostrarem a mesma coisa, e para o celular
/// reinstalado não pedir tudo de novo. O servidor não responde nada a partir
/// deles — a resposta do assistente continua saindo só do que ele mesmo
/// confere e calcula (T-05, RN-915).
final class FactRoutes {
  /// Cria as rotas sobre o registro [store] e a projeção [state].
  const new({required this.store, required this.state});

  /// O registro de eventos.
  final EventStore store;

  /// A projeção dos eventos.
  final LedgerState state;

  /// As rotas, para montar em `/v1`.
  Router get router => Router()
    ..get('/facts', _list)
    ..post('/facts', _keep);

  Response _list(Request request) => Responses.json({
    'facts': [for (final fact in state.facts) fact.toJson()],
  });

  /// Guarda o fato. A chave é o identificador que o aparelho deu a ele:
  /// mandar de novo não grava de novo.
  Future<Response> _keep(Request request) async {
    final fact = DeviceFact.read(await JsonBody.read(request));
    final event = await store.append(
      id: 'fact-${fact.id}',
      type: fact.type,
      payload: {'id': fact.id, 'payload': fact.payload},
    );
    state.apply(event);
    return Responses.json({'id': fact.id, 'seq': event.seq}, status: 201);
  }
}
