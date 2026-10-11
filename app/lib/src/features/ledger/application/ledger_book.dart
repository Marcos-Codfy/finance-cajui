import 'package:cajui/src/features/ledger/application/budget_facts.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_projection.dart';
import 'package:cajui/src/features/ledger/application/sync_trail.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O livro da casa como está agora: o resultado de aplicar, em ordem, todos
/// os fatos gravados.
///
/// É imutável. Aplicar um fato devolve um livro novo, o que deixa a tela
/// comparar "antes" e "depois" sem efeito colateral.
@immutable
final class LedgerBook {
  /// Cria o livro com o cadastro dado e nenhum lançamento.
  new({
    required this.categories,
    required this.paymentMethods,
    this.entries = const [],
    this.cards = const [],
    this.settlements = const [],
    this.receipts = const [],
    this.voucherAdjustments = const [],
    this.reversals = const [],
    this.debts = const [],
    this.debtPayments = const {},
    this.setup = MonthSetup.empty,
    this.budget = const BudgetFacts(),
    this.trail = const SyncTrail(),
    VoucherAccount? voucher,
  }) : voucher = voucher ?? VoucherAccount();

  /// As categorias em que se pode lançar.
  final List<Category> categories;

  /// As formas de pagamento de fábrica: Pix, débito, dinheiro, vale, boleto.
  /// Os cartões de crédito entram por [methods].
  final List<PaymentMethod> paymentMethods;

  /// Os lançamentos, na ordem em que foram gravados.
  final List<Entry> entries;

  /// Os cartões de crédito cadastrados.
  final List<CreditCard> cards;

  /// As faturas já pagas.
  final List<Settlement> settlements;

  /// As rendas já recebidas, nas duas moedas.
  final List<IncomeReceipt> receipts;

  /// Os acertos de saldo do vale já feitos (RN-123). Ficam guardados, e
  /// não só somados em [voucher], porque o servidor precisa deles: sem
  /// eles o saldo que ele calcula desanda do daqui no primeiro acerto.
  final List<VoucherAdjustment> voucherAdjustments;

  /// Os estornos: dinheiro de compra que voltou (RN-209).
  final List<Reversal> reversals;

  /// As dívidas cadastradas, com as parcelas pagas em dia (RN-501).
  final List<Debt> debts;

  /// Qual dívida cada lançamento de parcela pagou: lançamento → dívida.
  final Map<String, String> debtPayments;

  /// O plano do mês no formato antigo, de antes da planilha (ADR-023).
  final MonthSetup setup;

  /// Os planos da planilha e a ordem de quitação das dívidas (ADR-023).
  final BudgetFacts budget;

  /// Os planos da planilha já definidos, na ordem em que chegaram.
  List<BudgetPlan> get budgetPlans => budget.plans;

  /// A ordem de quitação das dívidas, a mais nova.
  List<String> get debtOrder => budget.debtOrder;

  /// O que a sincronização precisa saber além do estado: o que foi
  /// cancelado aqui e os fatos que sobem como estão.
  final SyncTrail trail;

  /// Os lançamentos cancelados **neste aparelho** (RN-208).
  Set<String> get cancelledIds => trail.cancelledIds;

  /// Os fatos que sobem ao servidor como estão (ADR-019).
  List<LedgerEvent> get facts => trail.facts;

  /// Os identificadores de [facts].
  Set<String> get factIds => trail.factIds;

  /// A conta do vale, com o saldo em vigor.
  final VoucherAccount voucher;

  /// Tudo por onde dá para pagar: as formas de fábrica e, depois, cada
  /// cartão cadastrado. Cartão é forma de pagamento, e só isso (RN-301).
  List<PaymentMethod> get methods => [
    ...paymentMethods,
    for (final card in cards)
      PaymentMethod(
        id: card.id,
        name: card.name,
        kind: PaymentMethodKind.creditCard,
      ),
  ];

  /// O livro depois de [event]. Como cada fato muda o livro está em
  /// [LedgerProjection].
  LedgerBook apply(LedgerEvent event) => LedgerProjection.apply(this, event);

  /// O mesmo livro com as partes dadas trocadas.
  LedgerBook copyWith({
    List<Entry>? entries,
    List<CreditCard>? cards,
    List<Settlement>? settlements,
    List<IncomeReceipt>? receipts,
    List<VoucherAdjustment>? voucherAdjustments,
    List<Reversal>? reversals,
    List<Debt>? debts,
    Map<String, String>? debtPayments,
    VoucherAccount? voucher,
    MonthSetup? setup,
    BudgetFacts? budget,
    SyncTrail? trail,
  }) => LedgerBook(
    categories: categories,
    paymentMethods: paymentMethods,
    entries: entries ?? this.entries,
    cards: cards ?? this.cards,
    settlements: settlements ?? this.settlements,
    receipts: receipts ?? this.receipts,
    voucherAdjustments: voucherAdjustments ?? this.voucherAdjustments,
    reversals: reversals ?? this.reversals,
    debts: debts ?? this.debts,
    debtPayments: debtPayments ?? this.debtPayments,
    setup: setup ?? this.setup,
    budget: budget ?? this.budget,
    trail: trail ?? this.trail,
    voucher: voucher ?? this.voucher,
  );

  /// As categorias pelo identificador, como o domínio pede para somar o mês.
  Map<String, Category> get categoriesById => {
    for (final category in categories) category.id: category,
  };

  /// Os lançamentos de [month], do mais recente para o mais antigo.
  List<Entry> entriesIn(BudgetMonth month) =>
      entries.where((entry) => month.contains(entry.occurredOn)).toList()
        ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

  /// O que foi gasto em [month], **por moeda**. Não existe total que some
  /// dinheiro e vale (RN-111). O estorno desconta no mês em que o dinheiro
  /// voltou, e não no da compra (RN-209).
  ///
  /// Quem decide o que conta é o domínio, e não esta soma: `Entry.spentIn`
  /// deixa a **linha parcelada de fora** (RN-311, RN-312), porque ela conta
  /// parcela a parcela, no bloco de dívidas. Somar `paidByTender` punha o
  /// fogão de R$ 960,00 inteiro no mês da compra — e o conceito central do
  /// Cajui é justamente esse não acontecer.
  TenderAmounts spentIn(BudgetMonth month) =>
      entriesIn(
        month,
      ).fold(TenderAmounts.zero, (sum, entry) => sum + entry.spentIn(month)) -
      reversedIn(month);

  /// O que voltou em [month], por moeda.
  TenderAmounts reversedIn(BudgetMonth month) => reversals
      .where((reversal) => month.contains(reversal.occurredOn))
      .fold(
        TenderAmounts.zero,
        (sum, r) => sum + TenderAmounts.single(r.line.tender, r.line.amount),
      );

  /// Os estornos do lançamento [entryId].
  List<Reversal> reversedOf(String entryId) => [
    ...reversals.where((reversal) => reversal.entryId == entryId),
  ];

  /// Quanto ainda pode voltar de [entry] pela forma [paymentMethodId]: o que
  /// a linha pagou menos o que já voltou por ela (RN-210).
  Money reversibleOn(Entry entry, String paymentMethodId) {
    final paid = entry.paymentLines
        .where((line) => line.paymentMethodId == paymentMethodId)
        .fold(Money.zero, (sum, line) => sum + line.amount);
    final back = reversedOf(entry.id)
        .where((r) => r.line.paymentMethodId == paymentMethodId)
        .fold(Money.zero, (sum, r) => sum + r.line.amount);
    return paid - back;
  }

  /// O lançamento de identificador [id], ou `null` — cancelado não aparece.
  Entry? entryOf(String id) =>
      entries.where((entry) => entry.id == id).firstOrNull;

  /// O identificador da fonte de renda em dinheiro do plano. O plano tem uma
  /// renda só; recebimento ligado a ela **substitui** o esperado no mês.
  static const cashIncomeSourceId = 'cash-income';

  IncomeSource get _cashSource => IncomeSource(
    id: cashIncomeSourceId,
    name: 'Renda em dinheiro',
    tender: Tender.cash,
    expectedAmount: setup.cashIncome,
    expectedDay: 5,
  );

  /// Se um recebimento em dinheiro de [amount] em [on] parece ser a renda do
  /// plano (RN-758) — e ela ainda não foi registrada naquele mês. Sem isso, o
  /// salário que chega pelo extrato ou pelo Pix entrava como avulso, por
  /// cima do esperado, e a renda do mês contava duas vezes.
  bool looksLikePlanIncome(Money amount, LocalDate on) =>
      _cashSource.looksLike(amount, on) &&
      !receipts.any(
        (receipt) =>
            receipt.sourceId == cashIncomeSourceId &&
            on.budgetMonth.contains(receipt.receivedOn),
      );

  /// A renda em dinheiro que vale em [month]: a recebida, se já houve
  /// recebimento da fonte do plano, senão a esperada — mais as entradas
  /// avulsas do mês (RN-131, RN-133). A conta é do domínio.
  Money cashIncomeIn(BudgetMonth month) => MonthIncome.of(
    month,
    sources: [_cashSource],
    receipts: receipts,
  ).amounts.cash;

  /// As parcelas que vencem em [month]: as das dívidas cadastradas (RN-504)
  /// e as das compras parceladas no cartão, que entram no mês como
  /// compromisso do bloco de dívidas, e não como gasto variável (RN-311 e
  /// RN-312). A conta é do domínio, que nunca conta a mesma parcela duas
  /// vezes.
  Money installmentsDueIn(BudgetMonth month) =>
      DebtSchedule.dueIn(month, debts: debts, entries: entries);

  /// A dívida de identificador [id], ou `null`.
  Debt? debtOf(String id) => debts.where((debt) => debt.id == id).firstOrNull;

  /// A renda em dinheiro que **de fato entrou** em [month]: só os
  /// recebimentos registrados.
  ///
  /// Não é a mesma conta de [cashIncomeIn], que vale o esperado do plano
  /// enquanto o recebimento não chega. Aqui, o que não foi registrado não
  /// entrou: é o que o fechamento precisa saber (RN-623).
  Money cashReceivedIn(BudgetMonth month) => receipts
      .where(
        (receipt) =>
            receipt.tender == Tender.cash && month.contains(receipt.receivedOn),
      )
      .fold(Money.zero, (sum, receipt) => sum + receipt.amount);

  /// O **resultado realizado** de [month]: a renda em dinheiro que entrou
  /// menos as despesas em dinheiro contadas no mês (RN-623). É o número que
  /// o fechamento congela.
  Money cashResultIn(BudgetMonth month) =>
      cashReceivedIn(month) - spentIn(month).cash;

  /// A categoria de identificador [id].
  Category categoryOf(String id) =>
      categories.firstWhere((category) => category.id == id);

  /// A forma de pagamento de identificador [id].
  PaymentMethod methodOf(String id) =>
      methods.firstWhere((method) => method.id == id);

  /// O cartão de identificador [id], ou `null`.
  CreditCard? cardOf(String id) =>
      cards.where((card) => card.id == id).firstOrNull;
}
