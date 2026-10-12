import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ledger/catalog_state.dart';
import 'package:server/src/ledger/income_state.dart';

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

  final CatalogState _catalog = CatalogState();
  final List<Entry> _entries = [];
  final Set<String> _cancelled = {};
  final IncomeState _income = IncomeState();
  final Map<String, Reversal> _reversals = {};
  final Map<String, DeviceFact> _facts = {};
  MonthSetup _plan = MonthSetup.empty;
  int _ledgerSeq = 0;

  /// O `seq` do último evento que mexeu no livro (ADR-024). É o que os
  /// aparelhos perguntam a cada 20 segundos: mudou, eles descem; não mudou,
  /// não gastam mais nada. Uso da IA não conta — não muda número nenhum.
  int get ledgerSeq => _ledgerSeq;

  /// O cadastro com a versão de cada item: categorias e cartões.
  CatalogState get catalog => _catalog;

  /// As categorias, por identificador.
  Map<String, Category> get categories => _catalog.categories;

  /// Os cartões cadastrados, por identificador.
  Map<String, CreditCard> get cards => _catalog.cards;

  /// Os lançamentos, na ordem em que entraram.
  List<Entry> get entries => List.unmodifiable(_entries);

  /// Os lançamentos que algum aparelho cancelou. Ficam listados para os
  /// outros aparelhos cancelarem também, em vez de mandá-los de volta
  /// (BL-062).
  Set<String> get cancelledIds => Set.unmodifiable(_cancelled);

  /// O plano do mês como o aparelho o cadastrou.
  MonthSetup get plan => _plan;

  /// Os fatos que só o aparelho interpreta — fatura paga, dívida, parcela
  /// de dívida, mês fechado —, na ordem em que chegaram. O servidor não
  /// faz conta com eles: guarda para o outro celular ter de onde trazer
  /// (ADR-019).
  List<DeviceFact> get facts => List.unmodifiable(_facts.values);

  /// Os estornos, por identificador.
  Map<String, Reversal> get reversals => Map.unmodifiable(_reversals);

  /// Os recebimentos em vigor, por identificador: o desfeito em algum
  /// aparelho (RN-1120) não está aqui, nem nos números da Juju.
  Map<String, IncomeReceipt> get receipts => _income.receipts;

  /// Os acertos de saldo do vale, por identificador, como foram gravados.
  Map<String, Map<String, Object?>> get voucherAdjustments =>
      _income.adjustments;

  /// O que entrou em [month], por moeda (RN-111).
  TenderAmounts receivedIn(BudgetMonth month) => _income.receivedIn(month);

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
    for (final raw in _income.adjustments.values) {
      account = account.adjust(Money.fromCents(raw['adjustmentCents']! as int));
    }
    for (final receipt in _income.receipts.values) {
      if (receipt.tender != Tender.mealVoucher) continue;
      account = account.credit(receipt.amount);
    }
    for (final entry in _entries) {
      account = account.settle(entry.paidByTender.mealVoucher);
    }
    for (final reversal in _reversals.values) {
      if (!_stillOnVoucher(reversal)) continue;
      account = account.reverse(reversal.line.amount);
    }
    return account;
  }

  /// Se o estorno ainda devolve saldo ao vale: foi no vale, o lançamento
  /// está vivo e **continua pago por ali**. Lançamento corrigido para outra
  /// forma de pagamento não tem mais o que devolver ao vale — e o servidor
  /// aceita a correção sem conferir os estornos, que no aparelho é papel
  /// do `CorrectionGuard`.
  bool _stillOnVoucher(Reversal reversal) {
    if (reversal.line.tender != Tender.mealVoucher) return false;
    final lines = entryOf(reversal.entryId)?.paymentLines ?? const [];
    return lines.any(
      (line) => line.paymentMethodId == reversal.line.paymentMethodId,
    );
  }

  /// Aplica um evento ao estado. Tipo desconhecido é ignorado: um servidor
  /// mais velho consegue subir sobre um registro mais novo.
  void apply(StoredEvent event) {
    if (!_project(event)) return;
    // O maior, e não o último: o registro devolve o evento **antigo** quando
    // a chave se repete, e reaplicá-lo não pode fazer o topo andar para trás.
    if (event.seq > _ledgerSeq) _ledgerSeq = event.seq;
  }

  /// Leva o evento à projeção, e diz se ele é do livro. Uso da IA, os
  /// aparelhos cadastrados do jeito antigo (`device.*`, de antes da
  /// ADR-020) e tipo que esta versão não conhece passam reto.
  bool _project(StoredEvent event) {
    switch (event.type) {
      case categoryCreated:
        _catalog.applyCategory(event.payload);
      case cardDefined:
        _catalog.applyCard(event.payload);
      case planDefined:
        // O plano mais novo pelo carimbo vence, e não o que chegou por
        // último: dois celulares sincronizam em horas diferentes, e o que
        // sincroniza tarde não pode apagar a edição mais recente do outro.
        final incoming = MonthSetupCodec.decode(event.payload);
        if (!_plan.isNewerThan(incoming)) _plan = incoming;
      case incomeReceived:
        _income.receive(event.payload);
      case voucherAdjusted:
        _income.adjust(event.payload);
      case entryCreated || entryRevised || entryCancelled || entryReversed:
        _applyEntry(event);
      case final type when DeviceFact.types.contains(type):
        final fact = _facts.putIfAbsent(
          '${event.payload['id']}',
          () => _factOf(event),
        );
        // O único fato do aparelho que muda conta aqui (RN-1120).
        if (type == DeviceFact.incomeCancelled) _income.cancel(fact.payload);
      default:
        return false;
    }
    return true;
  }

  /// O fato do aparelho como foi gravado: o evento leva o identificador e
  /// o conteúdo do fato lado a lado.
  static DeviceFact _factOf(StoredEvent event) => DeviceFact(
    id: '${event.payload['id']}',
    type: event.type,
    payload: (event.payload['payload']! as Map).cast<String, Object?>(),
  );

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
      category: categories[request.categoryId]!,
      today: today,
      // Sem isto, toda compra parcelada é recusada: as datas das parcelas
      // são **recalculadas** a partir do cartão (RN-311), e sem o cartão
      // não há de onde recalcular. O valor da parcela é aceito só depois
      // de conferido pelo codec (BL-063).
      cardOf: (id) => cards[id],
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
