import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';

/// As categorias e os lançamentos, reconstruídos a partir dos eventos.
///
/// O estado vive em memória e é uma **projeção**: apagado, refaz-se igual a
/// partir do registro. Nada aqui é fonte da verdade (ADR-004).
final class LedgerState {
  /// Reconstrói o estado aplicando os eventos [events], na ordem.
  new(Iterable<StoredEvent> events) {
    events.forEach(apply);
  }

  /// O tipo do evento de categoria criada.
  static const categoryCreated = 'category.created';

  /// O tipo do evento de cartão cadastrado.
  ///
  /// O servidor precisa dos cartões por um motivo só: **compra parcelada**.
  /// O plano de parcelas é recalculado a partir do cartão e da data — não
  /// se confia na parcela que o app mandou (T-05) —, e sem o cartão o
  /// domínio recusa o lançamento inteiro.
  static const cardDefined = 'card.defined';

  /// O tipo do evento de plano do mês definido.
  ///
  /// O plano não tem histórico aqui: vale o último que chegou. Sem ele o
  /// assistente sabe o que já saiu, mas não o que ainda cabe (BL-049).
  static const planDefined = 'plan.defined';

  /// O tipo do evento de recebimento: salário, crédito do vale, entrada
  /// avulsa. **Não é lançamento** (RN-132).
  static const incomeReceived = 'income.received';

  /// O tipo do evento de acerto do saldo do vale (RN-123).
  static const voucherAdjusted = 'voucher.adjusted';

  /// O tipo do evento de lançamento criado.
  static const entryCreated = 'entry.created';

  /// O tipo do evento de lançamento corrigido. **Nada é reescrito**
  /// (RN-208): o fato antigo continua no registro, e a projeção passa a
  /// mostrar o novo no lugar dele.
  static const entryRevised = 'entry.revised';

  /// O tipo do evento de lançamento cancelado. O cancelado sai de toda
  /// visão (RN-995), mas não some do registro.
  static const entryCancelled = 'entry.cancelled';

  /// O tipo do evento de **estorno**: dinheiro de uma compra que voltou.
  ///
  /// Sem ele o servidor contava o gasto inteiro depois de uma devolução, e
  /// o assistente respondia com um número que o aparelho já sabia errado.
  static const entryReversed = 'entry.reversed';

  final Map<String, Category> _categories = {};
  final Map<String, CreditCard> _cards = {};
  final List<Entry> _entries = [];
  final Set<String> _cancelled = {};
  final Map<String, IncomeReceipt> _receipts = {};
  final Map<String, Map<String, Object?>> _adjustments = {};
  final Map<String, Reversal> _reversals = {};
  MonthSetup _plan = MonthSetup.empty;

  /// As categorias, por identificador.
  Map<String, Category> get categories => Map.unmodifiable(_categories);

  /// Os cartões cadastrados, por identificador.
  Map<String, CreditCard> get cards => Map.unmodifiable(_cards);

  /// Os lançamentos, na ordem em que entraram.
  List<Entry> get entries => List.unmodifiable(_entries);

  /// Os lançamentos que algum aparelho cancelou. Ficam listados para os
  /// outros aparelhos cancelarem também, em vez de mandá-los de volta
  /// (BL-062).
  Set<String> get cancelledIds => Set.unmodifiable(_cancelled);

  /// O plano do mês como o aparelho o cadastrou.
  MonthSetup get plan => _plan;

  /// Os estornos, por identificador.
  Map<String, Reversal> get reversals => Map.unmodifiable(_reversals);

  /// Os recebimentos, por identificador.
  Map<String, IncomeReceipt> get receipts => Map.unmodifiable(_receipts);

  /// Os acertos de saldo do vale, por identificador, como foram gravados.
  Map<String, Map<String, Object?>> get voucherAdjustments =>
      Map.unmodifiable(_adjustments);

  /// O que entrou em [month], por moeda (RN-111).
  TenderAmounts receivedIn(BudgetMonth month) => _receipts.values
      .where((receipt) => month.contains(receipt.receivedOn))
      .fold(
        TenderAmounts.zero,
        (total, receipt) =>
            total + TenderAmounts.single(receipt.tender, receipt.amount),
      );

  /// O saldo do vale, **refeito a partir dos fatos**: créditos recebidos,
  /// menos o que os lançamentos vivos pagaram em vale, mais os acertos
  /// (RN-120). Ele passa inteiro de um mês para o outro (RN-121).
  ///
  /// É derivado, e não guardado ao lado, de propósito: corrigir e cancelar
  /// um lançamento já mexem na lista de lançamentos, e um saldo guardado
  /// teria de ser desfeito à mão em cada um desses caminhos.
  Money get voucherBalance => voucher.balance;

  /// A conta do vale, pela **mesma regra do aparelho**: a do domínio. A
  /// ordem dos fatos não muda o resultado, e o que passar do saldo fica a
  /// descoberto em vez de sumir (RN-124). O estorno em vale devolve saldo
  /// (RN-211) — só o de lançamento vivo: cancelado leva os estornos junto.
  VoucherAccount get voucher {
    var account = VoucherAccount();
    for (final raw in _adjustments.values) {
      account = account.adjust(Money.fromCents(raw['adjustmentCents']! as int));
    }
    for (final receipt in _receipts.values) {
      if (receipt.tender != Tender.mealVoucher) continue;
      account = account.credit(receipt.amount);
    }
    for (final entry in _entries) {
      account = account.settle(entry.paidByTender.mealVoucher);
    }
    for (final reversal in _reversals.values) {
      final alive = entryOf(reversal.entryId) != null;
      if (!alive || reversal.line.tender != Tender.mealVoucher) continue;
      account = account.reverse(reversal.line.amount);
    }
    return account;
  }

  /// Aplica um evento ao estado. Tipo desconhecido é ignorado: um servidor
  /// mais velho consegue subir sobre um registro mais novo.
  void apply(StoredEvent event) {
    switch (event.type) {
      case categoryCreated:
        final category = categoryFrom(event.payload);
        _categories[category.id] = category;
      case cardDefined:
        final card = CardCodec.decodeCard(event.payload);
        _cards[card.id] = card;
      case planDefined:
        // O plano mais novo pelo carimbo vence, e não o que chegou por
        // último: dois celulares sincronizam em horas diferentes, e o que
        // sincroniza tarde não pode apagar a edição mais recente do outro.
        final incoming = MonthSetupCodec.decode(event.payload);
        if (!_plan.isNewerThan(incoming)) _plan = incoming;
      case incomeReceived:
        final receipt = IncomeCodec.decode(event.payload);
        _receipts[receipt.id] = receipt;
      case voucherAdjusted:
        _adjustments['${event.payload['id']}'] = event.payload;
      case entryCreated || entryRevised || entryCancelled || entryReversed:
        _applyEntry(event);
    }
  }

  /// Os fatos que mexem nos lançamentos: criar, corrigir, cancelar, estornar.
  void _applyEntry(StoredEvent event) {
    switch (event.type) {
      case entryCreated:
        // Recriar o que já foi cancelado não acontece pela rota — ela recusa
        // —, mas o registro é a fonte da verdade, e a projeção não pode
        // depender de a rota ter existido.
        final id = '${event.payload['id']}';
        if (!_cancelled.contains(id) && entryOf(id) == null) {
          _entries.add(_replayed(event));
        }
      case entryRevised:
        _replace(_replayed(event));
      case entryCancelled:
        _entries.removeWhere((entry) => entry.id == event.payload['id']);
        _cancelled.add('${event.payload['id']}');
      case entryReversed:
        // O estorno já foi aceito quando aconteceu; reaplicá-lo não pode
        // falhar. Lançamento que sumiu da projeção leva o estorno junto.
        if (entryOf('${event.payload['entryId']}') case final entry?) {
          final reversal = tryReverse(event.payload, entry).valueOrNull;
          if (reversal != null) _reversals[reversal.id] = reversal;
        }
    }
  }

  /// Põe [entry] no lugar da versão anterior, **na mesma posição**: corrigir
  /// um lançamento não o manda para o fim da lista.
  ///
  /// Versão mais velha que a que está não entra: o outro aparelho corrigiu
  /// depois, e é a correção dele que vale (BL-062). A rota já recusa isso,
  /// mas o registro é a fonte da verdade, e a projeção não pode depender
  /// de a rota ter existido.
  void _replace(Entry entry) {
    if (_cancelled.contains(entry.id)) return;
    final at = _entries.indexWhere((existing) => existing.id == entry.id);
    if (at < 0) {
      _entries.add(entry);
      return;
    }
    if (_entries[at].isNewerThan(entry)) return;
    _entries[at] = entry;
  }

  /// A categoria descrita por [json].
  static Category categoryFrom(Map<String, Object?> json) => Category(
    id: json['id']! as String,
    name: json['name']! as String,
    block: EntryCodec.named(Block.values, json['block']! as String),
    groupId: json['groupId']! as String,
    voucherEligible: json['voucherEligible'] as bool? ?? false,
  );

  /// O evento já foi aceito quando aconteceu; reaplicá-lo não pode falhar por
  /// causa do relógio. Por isso "hoje", aqui, é o dia seguinte ao do evento.
  Entry _replayed(StoredEvent event) {
    final today = LocalDate.fromDateTime(event.at).addDays(1);
    final request = CreateEntryRequest.fromJson(event.payload);
    return tryCreate(request, today: today).valueOrNull!;
  }

  /// Aplica as regras do domínio ao pedido [request]. É o servidor validando
  /// **de novo** o que o app já validou: nunca se confia no cliente (T-05).
  Result<Entry> tryCreate(
    CreateEntryRequest request, {
    required LocalDate today,
  }) {
    return EntryCodec.toEntry(
      request,
      category: _categories[request.categoryId]!,
      today: today,
      // Sem isto, toda compra parcelada é recusada: o plano de parcelas é
      // **recalculado** a partir do cartão (T-05, nunca se confia na parcela
      // que o app mandou), e sem o cartão não há de onde recalcular.
      cardOf: (id) => _cards[id],
    );
  }

  /// O lançamento [id], ou `null` quando o servidor não o conhece.
  Entry? entryOf(String id) =>
      _entries.where((entry) => entry.id == id).firstOrNull;

  /// Aplica as regras do domínio ao estorno descrito por [payload], sobre o
  /// lançamento [entry]. O servidor confere de novo o que o app já conferiu
  /// (T-05): o estorno não pode passar do que resta na linha (RN-210).
  Result<Reversal> tryReverse(Map<String, Object?> payload, Entry entry) =>
      ReversalCodec.decode(
        payload,
        entry: entry,
        previous: _reversals.values.where((r) => r.entryId == entry.id),
      );

  /// A mesma leitura de data do contrato; fica aqui para as rotas que
  /// recebem data fora de um lançamento.
  static LocalDate parseDate(String text) => EntryCodec.parseDate(text);
}
