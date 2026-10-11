import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/fingerprint.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// As rotas do plano, dos lançamentos e dos estornos. O cadastro mora em
/// `CatalogRoutes`, e o topo do registro em `HeadRoutes` (ADR-024).
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
    ..get('/plan', _readPlan)
    ..post('/plan', _definePlan)
    ..get('/entries', _listEntries)
    ..post('/entries', _createEntry)
    ..put('/entries/<id>', _reviseEntry)
    ..delete('/entries/<id>', _cancelEntry)
    ..post('/entries/<id>/reversals', _reverseEntry)
    ..get('/reversals', _listReversals);

  Response _readPlan(Request request) =>
      Responses.json(MonthSetupCodec.encode(state.plan));

  /// O plano inteiro de uma vez, e não campo a campo: é assim que ele vive no
  /// aparelho, e mandar o conjunto evita um servidor com meio plano.
  ///
  /// A chave sai do próprio conteúdo, como na correção de lançamento:
  /// reenviar o mesmo plano não cria fato novo, e um plano diferente cria.
  Future<Response> _definePlan(Request request) async {
    final setup = MonthSetupCodec.read(await JsonBody.read(request));
    if (_isAhead(setup.definedAt)) {
      return Responses.error(request, ErrorCode.req01);
    }
    final payload = MonthSetupCodec.encode(setup);
    final event = await store.append(
      id: 'plan-${Fingerprint.of(payload)}',
      type: LedgerState.planDefined,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'seq': event.seq});
  }

  Response _listEntries(Request request) {
    final month = request.url.queryParameters['month'];
    final entries = state.entries.where(
      (entry) => month == null || '${entry.occurredOn.budgetMonth}' == month,
    );
    // O lançamento **inteiro**, pelo mesmo codec que o app usa para gravar.
    // Antes saíam só valor, data e categoria — e sem as linhas de pagamento
    // não dá para saber o que foi dinheiro e o que foi vale, que é a regra
    // central do produto (RN-111). A web precisa reconstruir o livro, não um
    // resumo dele.
    return Responses.json({
      'entries': [
        for (final entry in entries) EntryCodec.fromEntry(entry).toJson(),
      ],
      // O que morreu também é informação: é o que faz o outro aparelho
      // cancelar em vez de mandar de volta (BL-062).
      'cancelledIds': [...state.cancelledIds],
    });
  }

  Future<Response> _createEntry(Request request) async {
    final command = CreateEntryRequest.fromJson(await JsonBody.read(request));
    if (_gate(request, command) case final refused?) return refused;
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

  /// O lançamento como passou a valer (RN-208). A chave de idempotência sai
  /// do próprio conteúdo: reenviar a mesma correção não cria fato novo, e
  /// uma correção diferente cria — sem o app ter de contar revisões.
  Future<Response> _reviseEntry(Request request, String id) async {
    final json = await JsonBody.read(request);
    final command = CreateEntryRequest.fromJson(json);
    if (command.id != id) return Responses.error(request, ErrorCode.req02);
    if (_gate(request, command) case final refused?) return refused;
    final result = state.tryCreate(command, today: clock.today());
    if (result.failureOrNull case final failure?) {
      return _refuse(request, failure);
    }
    // A versão mais velha não passa por cima da mais nova: quem corrigiu
    // depois vence, e é a correção dele que desce (BL-062).
    if (state.entryOf(id)?.isNewerThan(result.valueOrNull!) ?? false) {
      return Responses.json({'id': id, 'kept': true});
    }
    final payload = command.toJson();
    final event = await store.append(
      id: 'entry-revised-$id-${Fingerprint.of(payload)}',
      type: LedgerState.entryRevised,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'id': id});
  }

  Response _listReversals(Request request) => Responses.json({
    'reversals': [
      for (final reversal in state.reversals.values)
        ReversalCodec.encode(reversal),
    ],
  });

  /// O dinheiro de uma compra voltou (RN-209).
  ///
  /// Não altera o lançamento original: é fato próprio, e o servidor confere
  /// de novo se ainda resta o que estornar naquela linha (RN-210, T-05).
  Future<Response> _reverseEntry(Request request, String id) async {
    final payload = ReversalCodec.read(await JsonBody.read(request));
    if (payload['entryId'] != id) {
      return Responses.error(request, ErrorCode.req02);
    }
    final entry = state.entryOf(id);
    if (entry == null) return Responses.error(request, ErrorCode.req02);
    final result = state.tryReverse(payload, entry);
    final failure = result.failureOrNull;
    if (failure != null) return _refuse(request, failure);
    final event = await store.append(
      id: 'reversal-${payload['id']}',
      type: LedgerState.entryReversed,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'id': payload['id']}, status: 201);
  }

  /// Cancelar não apaga: grava o fato de que aquele lançamento não vale mais.
  /// O que recusa um pedido de lançamento antes das regras: categoria que
  /// o servidor não conhece; lançamento que algum aparelho **já cancelou**,
  /// que não ressuscita por outro que ainda o tinha — o cancelamento é a
  /// ordem mais recente; e carimbo de correção **no futuro**, que travaria
  /// o lançamento para sempre contra o outro aparelho (T-05, T-40).
  Response? _gate(Request request, CreateEntryRequest command) {
    if (!state.categories.containsKey(command.categoryId)) {
      return Responses.error(request, ErrorCode.req02);
    }
    if (state.cancelledIds.contains(command.id)) {
      return Responses.json({'id': command.id, 'cancelled': true});
    }
    if (_isAhead(command.revisedAt)) {
      return Responses.error(request, ErrorCode.req01);
    }
    return null;
  }

  /// Se [stamp] está além do que um relógio honesto marcaria agora. A folga
  /// cobre celular alguns minutos adiantado; ano 9999 não passa.
  bool _isAhead(DateTime? stamp) =>
      stamp != null && stamp.isAfter(clock.now().add(stampTolerance));

  /// Quanto um carimbo pode estar à frente do relógio do servidor.
  static const stampTolerance = Duration(minutes: 10);

  /// Cancelar o que já está cancelado é repetição (200); cancelar o que
  /// nunca existiu seria inventar um cancelado eterno — recusa.
  Future<Response> _cancelEntry(Request request, String id) async {
    if (state.cancelledIds.contains(id)) {
      return Responses.json({'id': id, 'cancelled': true});
    }
    if (state.entryOf(id) == null) {
      return Responses.error(request, ErrorCode.req02);
    }
    final event = await store.append(
      id: 'entry-cancelled-$id',
      type: LedgerState.entryCancelled,
      payload: {'id': id},
    );
    state.apply(event);
    return Responses.json({'id': id});
  }

  Response _refuse(Request request, Failure failure) {
    final (code, detail) = FailureMapper.map(failure);
    return Responses.error(request, code, detail: detail);
  }
}
