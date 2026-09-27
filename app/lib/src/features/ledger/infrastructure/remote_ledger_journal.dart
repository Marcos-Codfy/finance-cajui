import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
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
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/entries', token: token),
    );
    final body = outcome.body;
    // Sem resposta não é "sem lançamentos": é "não sei". Quem for descer
    // não pode cancelar tudo por causa de uma queda de rede.
    if (body == null) return null;
    final cards = await _cards();
    final entries = [
      for (final item in body['entries'] as List<Object?>? ?? const [])
        ?_entryOf(item, cards),
    ];
    return (
      events: await _events(cards, entries),
      cancelled: {
        for (final id in body['cancelledIds'] as List<Object?>? ?? const [])
          '$id',
      },
    );
  }

  /// Os fatos na ordem em que o livro precisa deles. O plano, o que entrou
  /// e os cartões vêm antes dos lançamentos porque são o que dá sentido a
  /// eles: sem o plano não se sabe quanto cabe, sem o crédito do vale o
  /// saldo pararia em zero, e sem o cartão a compra parcelada nem se
  /// reconstrói. O estorno vem **depois**, e precisa do original em mãos: é
  /// dele que sai o que ainda resta a estornar (RN-210).
  Future<List<LedgerEvent>> _events(
    Map<String, CreditCard> cards,
    List<Entry> entries,
  ) async => [
    ...await _plan(),
    ...await _income(),
    for (final card in cards.values)
      CardDefined(id: 'card-remoto-${card.id}', card: card),
    for (final entry in entries) EntryRecorded(entry),
    ...await _reversals(entries),
  ];

  /// Os cartões, por identificador. Sem eles, toda compra parcelada era
  /// **silenciosamente pulada** na consulta: o plano de parcelas é
  /// recalculado a partir do cartão, e sem cartão não há de onde.
  Future<Map<String, CreditCard>> _cards() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/cards', token: token),
    );
    final lista = outcome.body?['cards'] as List<Object?>? ?? const [];
    final cards = <String, CreditCard>{};
    for (final item in lista) {
      if (item is! Map) continue;
      try {
        final card = CardCodec.decodeCard(item.cast<String, Object?>());
        cards[card.id] = card;
      } on Object {
        continue;
      }
    }
    return cards;
  }

  /// Os estornos que o servidor tem. Sem eles a consulta mostraria o gasto
  /// cheio de uma compra já devolvida (RN-209).
  Future<List<LedgerEvent>> _reversals(List<Entry> entries) async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/reversals', token: token),
    );
    final lista = outcome.body?['reversals'] as List<Object?>? ?? const [];
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
  Future<List<LedgerEvent>> _income() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/income', token: token),
    );
    final body = outcome.body;
    if (body == null) return const [];
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
  Future<List<LedgerEvent>> _plan() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/plan', token: token),
    );
    final body = outcome.body;
    if (body == null) return const [];
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
  Entry? _entryOf(Object? item, Map<String, CreditCard> cards) {
    if (item is! Map) return null;
    try {
      final pedido = CreateEntryRequest.fromJson(
        CreateEntryRequest.known(item.cast<String, Object?>()),
      );
      return EntryCodec.toEntry(
        pedido,
        category: _categoryOf(pedido.categoryId),
        cardOf: (id) => cards[id],
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
