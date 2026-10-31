import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/request_body.dart';
import 'package:server/src/ledger/fingerprint.dart';
import 'package:server/src/ledger/ledger_routes.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// As rotas do cadastro: categorias e cartões (ADR-024).
///
/// Cada item pode mudar depois de criado — o limite do cartão, o dia de
/// fechamento, o bloco de uma categoria —, e a mudança precisa atravessar
/// para o outro celular. Por isso a chave do evento leva a impressão do
/// conteúdo, e não só o identificador: com `card-<id>` a segunda versão
/// voltava como repetida e **sumia sem erro**. Entre duas versões, vale a
/// mais nova pelo carimbo `definedAt`.
final class CatalogRoutes {
  /// Cria as rotas sobre o registro [store], o estado [state] e o relógio.
  const new({required this.store, required this.state, required this.clock});

  /// O registro de eventos.
  final EventStore store;

  /// A projeção em memória.
  final LedgerState state;

  /// De onde vem a hora, para recusar carimbo no futuro.
  final Clock clock;

  /// O roteador, montado em `/v1`.
  Router get router => Router()
    ..get('/categories', _listCategories)
    ..post('/categories', _defineCategory)
    ..get('/cards', _listCards)
    ..post('/cards', _defineCard);

  Response _listCategories(Request request) => Responses.json({
    'categories': [
      for (final category in state.categories.values)
        state.catalog.encodeCategory(category),
    ],
  });

  Future<Response> _defineCategory(Request request) =>
      RequestBody.handle(request, _categoryBody, (read) async {
        final (:body, :name) = read;
        if (CategoryNamePolicy.check(name) case final refused?) {
          final (code, detail) = FailureMapper.map(refused);
          return Responses.error(request, code, detail: detail);
        }
        final category = Decoded.of(() => _categoryOf(body, name: name));
        if (category is! Understood<Category>) {
          return Responses.error(request, ErrorCode.req01);
        }
        return await _keep(
          request,
          body,
          prefix: 'category',
          type: LedgerState.categoryCreated,
          content: CategoryCodec.encode(category.value),
          current: state.catalog.categoryVersion(category.value.id),
        );
      });

  /// O corpo de uma categoria, com os campos que a rota aceita e o nome já
  /// lido: a política do nome só roda depois, para o erro dela ser o do
  /// catálogo e não um pedido malformado.
  static ({JsonReader body, String name}) _categoryBody(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {
        'id',
        'name',
        'block',
        'groupId',
        'voucherEligible',
        CatalogVersion.stampField,
      },
    );
    return (body: body, name: body.string('name', maxLength: 40));
  }

  /// A categoria lida de [body], já com o [name] conferido. Bloco que o
  /// domínio não conhece é pedido malformado (`E-REQ-01`).
  static Category _categoryOf(JsonReader body, {required String name}) =>
      CategoryCodec.decode({
        'id': body.string('id', maxLength: 64),
        'name': name,
        'block': body.string('block', maxLength: 16),
        'groupId': body.string('groupId', maxLength: 64),
        'voucherEligible': body.boolean('voucherEligible', orElse: false),
      });

  Response _listCards(Request request) => Responses.json({
    'cards': [
      for (final card in state.cards.values) state.catalog.encodeCard(card),
    ],
  });

  /// O cartão como forma de pagamento, e **nada de número de cartão**: só
  /// nome, dias e limite, que é o que a conta da fatura pede — e a cor do
  /// plástico, que é só aparência.
  Future<Response> _defineCard(Request request) =>
      RequestBody.handle(request, _cardBody, (read) async {
        final (:body, :card) = read;
        // Dia que não existe é recusa de regra (E-CARD-01, 422), e não
        // defeito do servidor.
        if (card.failureOrNull case final failure?) {
          final (code, detail) = FailureMapper.map(failure);
          return Responses.error(request, code, detail: detail);
        }
        final defined = card.valueOrNull!;
        return await _keep(
          request,
          body,
          prefix: 'card',
          type: LedgerState.cardDefined,
          content: CardCodec.encodeCard(defined),
          current: state.catalog.cardVersion(defined.id),
        );
      });

  /// O corpo de um cartão e o que o domínio disse do cartão que ele descreve.
  static ({JsonReader body, Result<CreditCard> card}) _cardBody(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {
        'id',
        'name',
        'closingDay',
        'dueDay',
        'creditLimitCents',
        'skin',
        CatalogVersion.stampField,
      },
    );
    final card = CardCodec.readCard({
      'id': body.string('id', maxLength: 64),
      'name': body.string('name', maxLength: 40),
      'closingDay': body.integer('closingDay'),
      'dueDay': body.integer('dueDay'),
      'creditLimitCents': body.optionalInteger('creditLimitCents'),
      'skin': body.optionalString('skin', maxLength: 20),
    });
    return (body: body, card: card);
  }

  /// Grava a versão que chegou, se ela é a que vale.
  ///
  /// A mais velha — ou a mesma de novo — não grava nada e responde 200 com
  /// `kept`: quem mandou desce a versão em vigor na mesma sincronização. O
  /// carimbo no futuro é recusado, porque travaria o item para sempre contra
  /// o outro aparelho (T-40).
  Future<Response> _keep(
    Request request,
    JsonReader body, {
    required String prefix,
    required String type,
    required Map<String, Object?> content,
    required CatalogVersion? current,
  }) async {
    final stamp = body.optionalInstant(CatalogVersion.stampField);
    final limit = clock.now().add(LedgerRoutes.stampTolerance);
    if (stamp != null && stamp.isAfter(limit)) {
      return Responses.error(request, ErrorCode.req01);
    }
    final payload = CatalogVersion.stamped(content, stamp);
    final id = '${content['id']}';
    if (!CatalogVersion.of(payload).replaces(current)) {
      return Responses.json({'id': id, 'kept': true});
    }
    final event = await store.append(
      id: '$prefix-$id-${Fingerprint.of(payload)}',
      type: type,
      payload: payload,
    );
    state.apply(event);
    return Responses.json({'id': id, 'seq': event.seq}, status: 201);
  }
}
