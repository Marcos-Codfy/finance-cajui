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

  /// As rendas já recebidas, nas duas moedas. A desfeita não está aqui
  /// (RN-1120): sai do mês, da renda, da planilha e do Início de uma vez.
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

  /// Os nomes da casa em vigor (RN-1070).
  HouseholdNames get householdNames => budget.household;

  /// O que a sincronização precisa saber além do estado: o que foi
  /// cancelado aqui e os fatos que sobem como estão.
  final SyncTrail trail;

  /// Os lançamentos cancelados **neste aparelho** (RN-208).
  Set<String> get cancelledIds => trail.cancelledIds;

  /// Os fatos que sobem ao servidor como estão (ADR-019).
  List<LedgerEvent> get facts => trail.facts;

  /// Os identificadores de [facts].
  Set<String> get factIds => trail.factIds;

  /// Os recebimentos desfeitos, aqui ou no outro celular (RN-1120). Saem
  /// dos fatos, e não de [receipts]: o recebimento que descer depois do
  /// desfazer não pode voltar a valer.
  Set<String> get cancelledReceiptIds => {
    for (final fact in facts)
      if (fact is IncomeCancelled) fact.receiptId,
  };

  /// Todas as respostas lembradas, na ordem em que chegaram (RN-1116).
  ///
  /// Saem dos fatos, todas, e não só as em vigor: a mais nova vence venha
  /// na ordem que vier, e guardando só as em vigor uma resposta velha do
  /// outro celular, chegando depois de um "esquecer", voltaria a valer.
  List<LearnedAnswer> get answerHistory => [
    for (final fact in facts)
      if (fact is AnswerLearned) fact.answer,
  ];

  /// As respostas lembradas em vigor: a mais nova de cada chave, venha do
  /// celular que vier, sem as esquecidas. A conta é do domínio.
  LearnedAnswers get learnedAnswers => LearnedAnswers.of(answerHistory);

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

  /// A dívida de identificador [id], ou `null`.
  Debt? debtOf(String id) => debts.where((debt) => debt.id == id).firstOrNull;

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
