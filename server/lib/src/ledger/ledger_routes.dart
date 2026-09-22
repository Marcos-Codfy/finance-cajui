import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:pointycastle/export.dart';
import 'package:server/src/http/error_response.dart';
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
    ..get('/cards', _listCards)
    ..post('/cards', _createCard)
    ..get('/plan', _readPlan)
    ..post('/plan', _definePlan)
    ..get('/entries', _listEntries)
    ..post('/entries', _createEntry)
    ..put('/entries/<id>', _reviseEntry)
    ..delete('/entries/<id>', _cancelEntry);

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

  Response _listCards(Request request) => Responses.json({
    'cards': [
      for (final card in state.cards.values) CardCodec.encodeCard(card),
    ],
  });

  /// O cartão como forma de pagamento, e **nada de número de cartão**: só
  /// nome, dias e limite, que é o que a conta da fatura pede.
  Future<Response> _createCard(Request request) async {
    final json = await JsonBody.read(request);
    final body = JsonReader(
      json,
      allowed: const {'id', 'name', 'closingDay', 'dueDay', 'creditLimitCents'},
    );
    final card = CardCodec.decodeCard({
      'id': body.string('id', maxLength: 64),
      'name': body.string('name', maxLength: 40),
      'closingDay': body.integer('closingDay'),
      'dueDay': body.integer('dueDay'),
      'creditLimitCents': body.optionalInteger('creditLimitCents'),
    });
    final event = await store.append(
      id: 'card-${card.id}',
      type: LedgerState.cardDefined,
      payload: CardCodec.encodeCard(card),
    );
    state.apply(event);
    return Responses.json({'id': card.id}, status: 201);
  }

  Response _readPlan(Request request) =>
      Responses.json(MonthSetupCodec.encode(state.plan));

  /// O plano inteiro de uma vez, e não campo a campo: é assim que ele vive no
  /// aparelho, e mandar o conjunto evita um servidor com meio plano.
  ///
  /// A chave sai do próprio conteúdo, como na correção de lançamento:
  /// reenviar o mesmo plano não cria fato novo, e um plano diferente cria.
  Future<Response> _definePlan(Request request) async {
    final setup = MonthSetupCodec.read(await JsonBody.read(request));
    final payload = MonthSetupCodec.encode(setup);
    final event = await store.append(
      id: 'plan-${_fingerprint(payload)}',
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

  /// O lançamento como passou a valer (RN-208). A chave de idempotência sai
  /// do próprio conteúdo: reenviar a mesma correção não cria fato novo, e
  /// uma correção diferente cria — sem o app ter de contar revisões.
  Future<Response> _reviseEntry(Request request, String id) async {
    final json = await JsonBody.read(request);
    final command = CreateEntryRequest.fromJson(json);
    if (command.id != id) return Responses.error(request, ErrorCode.req02);
    if (!state.categories.containsKey(command.categoryId)) {
      return Responses.error(request, ErrorCode.req02);
    }
    final failure = state
        .tryCreate(command, today: clock.today())
        .failureOrNull;
    if (failure != null) return _refuse(request, failure);
    final payload = command.toJson();
    final event = await store.append(
      id: 'entry-revised-$id-${_fingerprint(payload)}',
      type: LedgerState.entryRevised,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'id': id});
  }

  /// Cancelar não apaga: grava o fato de que aquele lançamento não vale mais.
  Future<Response> _cancelEntry(Request request, String id) async {
    final event = await store.append(
      id: 'entry-cancelled-$id',
      type: LedgerState.entryCancelled,
      payload: {'id': id},
    );
    state.apply(event);
    return Responses.json({'id': id});
  }

  /// Oito caracteres do SHA-256 do conteúdo: o bastante para separar duas
  /// correções e curto o bastante para caber num identificador legível.
  static String _fingerprint(Map<String, Object?> payload) {
    final bytes = utf8.encode(jsonEncode(payload));
    final digest = SHA256Digest().process(Uint8List.fromList(bytes));
    return digest
        .take(4)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Response _refuse(Request request, Failure failure) {
    final (code, detail) = FailureMapper.map(failure);
    return Responses.error(request, code, detail: detail);
  }
}
