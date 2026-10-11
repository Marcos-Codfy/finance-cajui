import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/device_facts.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:domain/domain.dart';

/// O livro visto de fora: o que **o servidor** tem (ADR-013).
///
/// Serve a dois usos. Na web, é o próprio livro: ela não tem registro, e o
/// que tinha antes era um livro vazio na memória, que mostrava "R$ 0,00" com
/// cara de verdade. No celular, é a **descida** (BL-062): o que o outro
/// aparelho fez chega por aqui e vira fato no registro local.
///
/// Só lê. `append` recusa por construção: a web é modo consulta, e isso não
/// se garante escondendo botão (T-12, RN-906) — se alguém chamar, estoura
/// aqui, e o teste pega.
///
/// A leitura é **inteira ou nenhuma**: se uma das partes não respondeu, o
/// retrato inteiro é "não sei" (`null`). Com a web relendo a cada mudança
/// feita no celular (ADR-024), um plano que falhasse no meio deixaria a
/// tela sem plano até a próxima mudança — e a descida no celular trataria
/// o cartão que não veio como cartão que não existe.
final class RemoteLedgerJournal implements LedgerJournal, LedgerDownlink {
  /// Cria o livro remoto sobre [_api].
  const new(this._api, {required this._categoryOf});

  final CajuiApi _api;
  final Category Function(String id) _categoryOf;

  @override
  Future<List<LedgerEvent>> readAll() async =>
      (await snapshot())?.events ?? const [];

  @override
  Future<LedgerSnapshot?> snapshot() async {
    final (body, cards) = await (_get('/v1/entries'), _cards()).wait;
    // Sem resposta não é "sem lançamentos": é "não sei". Quem for descer
    // não pode cancelar tudo por causa de uma queda de rede.
    if (body == null || cards == null) return null;
    final entries = [
      for (final item in body['entries'] as List<Object?>? ?? const [])
        ?_entryOf(item, cards),
    ];
    final events = await _events(cards, entries);
    if (events == null) return null;
    return (
      events: events,
      cancelled: {
        for (final id in body['cancelledIds'] as List<Object?>? ?? const [])
          '$id',
      },
    );
  }

  /// O corpo da resposta a `GET` [path]; `null` quando não houve resposta.
  Future<Map<String, Object?>?> _get(String path) async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', path, token: token),
    );
    return outcome.body;
  }

  /// Os fatos na ordem em que o livro precisa deles. O plano, o que entrou
  /// e os cartões vêm antes dos lançamentos porque são o que dá sentido a
  /// eles: sem o plano não se sabe quanto cabe, sem o crédito do vale o
  /// saldo pararia em zero, e sem o cartão a compra parcelada nem se
  /// reconstrói. O estorno vem **depois**, e precisa do original em mãos: é
  /// dele que sai o que ainda resta a estornar (RN-210).
  Future<List<LedgerEvent>?> _events(
    Map<String, CardDefined> cards,
    List<Entry> entries,
  ) async {
    final (plan, income, reversals, facts) = await (
      _plan(),
      _income(),
      _reversals(entries),
      _facts(),
    ).wait;
    if (plan == null || income == null || reversals == null) return null;
    if (facts == null) return null;
    return [
      ...plan,
      ...income,
      ...cards.values,
      for (final entry in entries) EntryRecorded(entry),
      ...reversals,
      ...facts,
    ];
  }

  /// Os fatos que o servidor guarda sem fazer conta: fatura paga, dívida,
  /// parcela de dívida paga e mês fechado (ADR-019). Vêm por último — a
  /// parcela paga aponta para um lançamento. Fato que esta versão não lê
  /// é pulado, e não derruba os outros.
  Future<List<LedgerEvent>?> _facts() async {
    final body = await _get('/v1/facts');
    if (body == null) return null;
    final list = body['facts'] as List<Object?>? ?? const [];
    return [for (final item in list) ?_factOf(item)];
  }

  static LedgerEvent? _factOf(Object? item) {
    if (item is! Map) return null;
    try {
      return DeviceFacts.toEvent(
        DeviceFact(
          id: '${item['id']}',
          type: '${item['type']}',
          payload: (item['payload']! as Map).cast<String, Object?>(),
        ),
      );
    } on Object {
      return null;
    }
  }

  /// Os cartões, por identificador, cada um com o carimbo da versão que o
  /// servidor tem (ADR-024). Sem eles, toda compra parcelada era
  /// **silenciosamente pulada** na consulta: o plano de parcelas é
  /// recalculado a partir do cartão, e sem cartão não há de onde.
  Future<Map<String, CardDefined>?> _cards() async {
    final body = await _get('/v1/cards');
    if (body == null) return null;
    final cards = <String, CardDefined>{};
    for (final item in body['cards'] as List<Object?>? ?? const []) {
      final defined = _cardOf(item);
      if (defined != null) cards[defined.card.id] = defined;
    }
    return cards;
  }

  static CardDefined? _cardOf(Object? item) {
    if (item is! Map) return null;
    try {
      final payload = item.cast<String, Object?>();
      final card = CardCodec.decodeCard(payload);
      return CardDefined(
        id: 'card-remoto-${card.id}',
        card: card,
        definedAt: CatalogVersion.definedAtOf(payload),
      );
    } on Object {
      return null;
    }
  }

  /// Os estornos que o servidor tem. Sem eles a consulta mostraria o gasto
  /// cheio de uma compra já devolvida (RN-209).
  Future<List<LedgerEvent>?> _reversals(List<Entry> entries) async {
    final body = await _get('/v1/reversals');
    if (body == null) return null;
    final lista = body['reversals'] as List<Object?>? ?? const [];
    final porId = {for (final entry in entries) entry.id: entry};
    final feitos = <Reversal>[];
    for (final item in lista) {
      if (item is! Map) continue;
      final payload = item.cast<String, Object?>();
      final entry = porId['${payload['entryId']}'];
      if (entry == null) continue;
      final reversal = ReversalCodec.decode(
        payload,
        entry: entry,
        previous: feitos.where((r) => r.entryId == entry.id),
      ).valueOrNull;
      if (reversal != null) feitos.add(reversal);
    }
    return [for (final reversal in feitos) EntryReversed(reversal)];
  }

  /// O que entrou, como o servidor tem: os recebimentos e os acertos de
  /// saldo. O saldo em si não desce pronto — ele nasce da projeção, aqui,
  /// pelos mesmos fatos e pelas mesmas regras do aparelho.
  Future<List<LedgerEvent>?> _income() async {
    final body = await _get('/v1/income');
    if (body == null) return null;
    return [
      for (final item in body['receipts'] as List<Object?>? ?? const [])
        if (item is Map)
          IncomeReceived(IncomeCodec.decode(item.cast<String, Object?>())),
      for (final item
          in body['voucherAdjustments'] as List<Object?>? ?? const [])
        if (item is Map)
          VoucherBalanceAdjusted(
            IncomeCodec.decodeAdjustment(
              item.cast<String, Object?>(),
              orElse: 'acerto-remoto',
            ),
          ),
    ];
  }

  /// Servidor que ainda não recebeu plano nenhum devolve um plano vazio, e
  /// aí não há fato a aplicar: o livro nasce sem plano, como no aparelho.
  Future<List<LedgerEvent>?> _plan() async {
    final body = await _get('/v1/plan');
    if (body == null) return null;
    final setup = MonthSetupCodec.decode(body);
    // O identificador é fixo porque aqui só existe um plano: o que o
    // servidor tem agora. A consulta não guarda o histórico dele.
    return setup.isEmpty
        ? const []
        : [PlanDefined(id: 'plan-remoto', setup: setup)];
  }

  /// Lançamento que o app não consegue reconstruir — categoria que ele não
  /// conhece, formato de um servidor mais novo — é **pulado**, e não derruba
  /// a tela inteira. Ver um mês quase completo é melhor que ver um erro.
  Entry? _entryOf(Object? item, Map<String, CardDefined> cards) {
    if (item is! Map) return null;
    try {
      final pedido = CreateEntryRequest.fromJson(
        CreateEntryRequest.known(item.cast<String, Object?>()),
      );
      return EntryCodec.toEntry(
        pedido,
        category: _categoryOf(pedido.categoryId),
        cardOf: (id) => cards[id]?.card,
        // O lançamento já foi aceito quando aconteceu: reconstruí-lo não
        // pode falhar por causa do relógio de quem está olhando.
        today: EntryCodec.parseDate(pedido.occurredOn).addDays(1),
      ).valueOrNull;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> append(LedgerEvent event) =>
      throw StateError('A consulta não grava: lançar é no celular.');
}
