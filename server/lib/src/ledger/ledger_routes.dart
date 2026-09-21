import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/failure_mapper.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// As rotas de categorias e de lançamentos, e a âncora do registro.
///
/// O caminho de toda escrita é o mesmo: ler o pedido com formato estrito,
/// aplicar as regras do domínio, **gravar o evento** e só então atualizar o
/// estado em memória e responder.
final class LedgerRoutes {
  /// Cria as rotas sobre o registro [store], o estado [state] e o relógio.
  new({required this.store, required this.state, required this.clock});

  /// O registro de eventos.
  final EventStore store;

  /// A projeção em memória.
  final LedgerState state;

  /// De onde vem o dia de hoje, no fuso de negócio.
  final Clock clock;

  /// O roteador, montado em `/v1`.
  Router get router => Router()
    ..get('/head', _head)
    ..get('/categories', _listCategories)
    ..post('/categories', _createCategory)
    ..get('/entries', _listEntries)
    ..post('/entries', _createEntry);

  /// A âncora contra o corte do fim do registro (T-39): o app guarda o maior
  /// `seq` que já viu, e estranha um servidor que sabe menos do que ele.
  Response _head(Request request) =>
      Responses.json({'seq': store.events.length});

  Response _listCategories(Request request) => Responses.json({
    'categories': [
      for (final category in state.categories.values)
        {
          'id': category.id,
          'name': category.name,
          'block': category.block.name,
          'groupId': category.groupId,
          'voucherEligible': category.voucherEligible,
        },
    ],
  });

  Future<Response> _createCategory(Request request) async {
    final json = await JsonBody.read(request);
    final body = JsonReader(
      json,
      allowed: const {'id', 'name', 'block', 'groupId', 'voucherEligible'},
    );
    final name = body.string('name', maxLength: 40);
    final refused = CategoryNamePolicy.check(name);
    if (refused != null) return _refuse(request, refused);
    final payload = {
      'id': body.string('id', maxLength: 64),
      'name': name,
      'block': body.string('block', maxLength: 16),
      'groupId': body.string('groupId', maxLength: 64),
      'voucherEligible': body.boolean('voucherEligible', orElse: false),
    };
    LedgerState.categoryFrom(payload);
    final event = await store.append(
      id: 'category-${payload['id']}',
      type: LedgerState.categoryCreated,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'id': payload['id']}, status: 201);
  }

  Response _listEntries(Request request) {
    final month = request.url.queryParameters['month'];
    final entries = state.entries.where(
      (entry) => month == null || '${entry.occurredOn.budgetMonth}' == month,
    );
    return Responses.json({
      'entries': [
        for (final entry in entries)
          {
            'id': entry.id,
            'description': entry.description,
            'amountCents': entry.amount.cents,
            'occurredOn': '${entry.occurredOn}',
            'categoryId': entry.categoryId,
            'isExceptional': entry.isExceptional,
          },
      ],
    });
  }

  Future<Response> _createEntry(Request request) async {
    final command = CreateEntryRequest.fromJson(await JsonBody.read(request));
    if (!state.categories.containsKey(command.categoryId)) {
      return Responses.error(request, ErrorCode.req02);
    }
    final known = state.entries.any((entry) => entry.id == command.id);
    final result = state.tryCreate(command, today: clock.today());
    final failure = result.failureOrNull;
    if (failure != null) return _refuse(request, failure);
    final event = await store.append(
      // O prefixo separa os identificadores por tipo: um lançamento nunca
      // colide com uma categoria ou com um aparelho de mesmo `id`.
      id: 'entry-${command.id}',
      type: LedgerState.entryCreated,
      payload: command.toJson(),
    );
    if (!known) state.apply(event);
    return Responses.json({'id': command.id, 'seq': event.seq}, status: 201);
  }

  Response _refuse(Request request, Failure failure) {
    final (code, detail) = FailureMapper.map(failure);
    return Responses.error(request, code, detail: detail);
  }
}
