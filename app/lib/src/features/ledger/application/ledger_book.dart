import 'package:cajui/src/features/budget/application/month_setup.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
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
    this.setup = MonthSetup.empty,
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

  /// O plano do mês em vigor.
  final MonthSetup setup;

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

  /// O livro depois de [event].
  LedgerBook apply(LedgerEvent event) => switch (event) {
    EntryRecorded(:final entry) => _with(
      entries: [...entries, entry],
      // O fato já foi aceito quando aconteceu. Se o registro antigo disser
      // que o vale pagou mais do que tinha, o saldo para em zero: é melhor
      // abrir com saldo zerado do que não abrir.
      voucher:
          voucher.pay(entry.paidByTender.mealVoucher).valueOrNull ??
          VoucherAccount(),
    ),
    VoucherBalanceAdjusted(:final adjustment) => _with(
      voucher: voucher.adjust(adjustment),
    ),
    PlanDefined(:final setup) => _with(setup: setup),
    // A versão mais recente do cartão toma o lugar da anterior.
    CardDefined(:final card) => _with(
      cards: [...cards.where((known) => known.id != card.id), card],
    ),
    StatementSettled(:final settlement) => _with(
      settlements: [...settlements, settlement],
    ),
    // O crédito do vale entra no saldo (RN-120); renda em dinheiro só fica
    // registrada — o app não conhece o saldo da conta de ninguém.
    IncomeReceived(:final receipt) => _with(
      receipts: [...receipts, receipt],
      voucher: receipt.tender == Tender.mealVoucher
          ? voucher.credit(receipt.amount)
          : voucher,
    ),
  };

  LedgerBook _with({
    List<Entry>? entries,
    List<CreditCard>? cards,
    List<Settlement>? settlements,
    List<IncomeReceipt>? receipts,
    VoucherAccount? voucher,
    MonthSetup? setup,
  }) => LedgerBook(
    categories: categories,
    paymentMethods: paymentMethods,
    entries: entries ?? this.entries,
    cards: cards ?? this.cards,
    settlements: settlements ?? this.settlements,
    receipts: receipts ?? this.receipts,
    setup: setup ?? this.setup,
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
  /// dinheiro e vale (RN-111).
  TenderAmounts spentIn(BudgetMonth month) =>
      entriesIn(month)
          .fold(TenderAmounts.zero, (sum, entry) => sum + entry.paidByTender);

  /// O identificador da fonte de renda em dinheiro do plano. O plano tem uma
  /// renda só; recebimento ligado a ela **substitui** o esperado no mês.
  static const cashIncomeSourceId = 'cash-income';

  /// A renda em dinheiro que vale em [month]: a recebida, se já houve
  /// recebimento da fonte do plano, senão a esperada — mais as entradas
  /// avulsas do mês (RN-131, RN-133). A conta é do domínio.
  Money cashIncomeIn(BudgetMonth month) => MonthIncome.of(
    month,
    sources: [
      IncomeSource(
        id: cashIncomeSourceId,
        name: 'Renda em dinheiro',
        tender: Tender.cash,
        expectedAmount: setup.cashIncome,
        expectedDay: 5,
      ),
    ],
    receipts: receipts,
  ).amounts.cash;

  /// As parcelas de compras no cartão que vencem em [month]: entram no mês
  /// como compromisso do bloco de dívidas, e não como gasto variável
  /// (RN-311 e RN-312).
  Money installmentsDueIn(BudgetMonth month) => entries.fold(
    Money.zero,
    (sum, entry) =>
        sum +
        (entry.installmentPlan?.installmentDueIn(month)?.amount ?? Money.zero),
  );

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
