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
    this.setup = MonthSetup.empty,
    VoucherAccount? voucher,
  }) : voucher = voucher ?? VoucherAccount();

  /// As categorias em que se pode lançar.
  final List<Category> categories;

  /// As formas de pagamento cadastradas.
  final List<PaymentMethod> paymentMethods;

  /// Os lançamentos, na ordem em que foram gravados.
  final List<Entry> entries;

  /// O plano do mês em vigor.
  final MonthSetup setup;

  /// A conta do vale, com o saldo em vigor.
  final VoucherAccount voucher;

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
  };

  LedgerBook _with({
    List<Entry>? entries,
    VoucherAccount? voucher,
    MonthSetup? setup,
  }) => LedgerBook(
    categories: categories,
    paymentMethods: paymentMethods,
    entries: entries ?? this.entries,
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

  /// A categoria de identificador [id].
  Category categoryOf(String id) =>
      categories.firstWhere((category) => category.id == id);

  /// A forma de pagamento de identificador [id].
  PaymentMethod methodOf(String id) =>
      paymentMethods.firstWhere((method) => method.id == id);
}
