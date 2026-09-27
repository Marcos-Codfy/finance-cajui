import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/card/installment_plan.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/ledger/entry_origin.dart';
import 'package:domain/src/ledger/payment_line.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:domain/src/money/tender_amounts.dart';
import 'package:domain/src/shared/edit_stamp.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// Um lançamento: **o que** foi comprado (descrição, valor, data, categoria)
/// e **por onde** foi pago (as linhas de pagamento).
///
/// É a ideia central do Cajui: cartão de crédito é forma de pagamento, não
/// despesa. Não existe lançamento "fatura do cartão" (RN-207) — o que existe
/// é um lançamento de mercado, pago no cartão.
///
/// Só nasce por [Entry.create], que aplica as regras. Um lançamento que
/// existe é um lançamento válido.
@immutable
final class Entry {
  new _({
    required this.id,
    required this.description,
    required this.amount,
    required this.occurredOn,
    required this.categoryId,
    required this.paymentLines,
    required this.isExceptional,
    required this.origin,
    required this.installmentPlan,
    required this.revisedAt,
  }) : assert(
         installmentPlan == null || _planMatches(installmentPlan, paymentLines),
         'O parcelamento precisa valer exatamente a linha do cartão parcelado.',
       );

  /// O identificador do lançamento.
  final String id;

  /// O que foi, nas palavras de quem lançou: "Mercado Boa Compra".
  final String description;

  /// O valor da compra, sempre maior que zero (RN-104).
  final Money amount;

  /// A data da compra, nunca no futuro (RN-206).
  final LocalDate occurredOn;

  /// A categoria, que define o bloco (RN-202).
  final String categoryId;

  /// Por onde foi pago. A soma é exatamente [amount] (RN-203).
  final List<PaymentLine> paymentLines;

  /// Gasto fora do padrão: não se repete, e soma-se entre categorias
  /// (RN-240).
  final bool isExceptional;

  /// Como o lançamento nasceu.
  final EntryOrigin origin;

  /// O parcelamento, quando a linha do cartão foi parcelada.
  final InstallmentPlan? installmentPlan;

  /// Quando este lançamento foi corrigido pela última vez, em UTC; `null`
  /// quando nunca foi. É o que decide entre dois celulares que corrigiram
  /// a mesma compra: vale a correção mais nova, e não a que sincronizou
  /// por último (BL-062).
  final DateTime? revisedAt;

  /// Se esta versão é mais nova que [other], pelo carimbo de correção.
  bool isNewerThan(Entry other) =>
      EditStamp.isNewer(revisedAt, other.revisedAt);

  /// Quanto saiu em dinheiro e quanto saiu em vale, separados (RN-111).
  TenderAmounts get paidByTender => _sum(paymentLines);

  /// Quanto do lançamento conta como **gasto da categoria** em [month].
  ///
  /// Tudo o que não foi parcelado conta no mês da compra — inclusive a compra
  /// à vista no cartão, embora o dinheiro só saia na fatura (RN-250 e
  /// RN-310). A linha parcelada fica de fora: ela conta parcela a parcela, no
  /// bloco de dívidas (RN-311 e RN-312).
  TenderAmounts spentIn(BudgetMonth month) {
    if (occurredOn.budgetMonth != month) return TenderAmounts.zero;
    return _sum(paymentLines.where((line) => !_isInstallmentLine(line)));
  }

  bool _isInstallmentLine(PaymentLine line) =>
      line.kind.isCreditCard && line.paymentMethodId == installmentPlan?.cardId;

  static TenderAmounts _sum(Iterable<PaymentLine> lines) => lines.fold(
    TenderAmounts.zero,
    (sum, line) => sum + TenderAmounts.single(line.tender, line.amount),
  );

  /// Cria um lançamento, ou devolve a regra que o recusou.
  static Result<Entry> create({
    required String id,
    required String description,
    required Money amount,
    required LocalDate occurredOn,
    required Category category,
    required List<PaymentLine> paymentLines,
    required LocalDate today,
    bool isExceptional = false,
    EntryOrigin origin = EntryOrigin.manual,
    InstallmentPlan? installmentPlan,
    DateTime? revisedAt,
  }) {
    return _validate(amount, paymentLines, occurredOn, today, category) ??
        Ok(
          Entry._(
            id: id,
            description: description.trim(),
            amount: amount,
            occurredOn: occurredOn,
            categoryId: category.id,
            paymentLines: List.unmodifiable(paymentLines),
            isExceptional: isExceptional,
            origin: origin,
            installmentPlan: installmentPlan,
            revisedAt: revisedAt?.toUtc(),
          ),
        );
  }

  static bool _planMatches(InstallmentPlan plan, List<PaymentLine> lines) =>
      lines.any(
        (line) =>
            line.kind.isCreditCard &&
            line.paymentMethodId == plan.cardId &&
            line.amount == plan.principal,
      );

  /// A primeira regra que recusa o lançamento, ou nulo se todas aceitam.
  static Err<Entry>? _validate(
    Money amount,
    List<PaymentLine> lines,
    LocalDate occurredOn,
    LocalDate today,
    Category category,
  ) {
    final failure =
        _amountFailure(amount, lines) ??
        _dateFailure(occurredOn, today) ??
        _voucherFailure(category, lines);
    return failure == null ? null : Err(failure);
  }

  /// RN-104 e RN-203: valor positivo, linhas positivas, soma exata.
  static Failure? _amountFailure(Money amount, List<PaymentLine> lines) {
    if (!amount.isPositive) return NonPositiveAmount(amount);
    for (final line in lines) {
      if (!line.amount.isPositive) return NonPositiveAmount(line.amount);
    }
    final total = lines.fold(Money.zero, (sum, line) => sum + line.amount);
    if (total != amount) {
      return PaymentLinesMismatch(amount: amount, linesTotal: total);
    }
    return null;
  }

  /// RN-206: compromisso futuro é item de plano, não lançamento.
  static Failure? _dateFailure(LocalDate occurredOn, LocalDate today) {
    if (!occurredOn.isAfter(today)) return null;
    return PurchaseDateInFuture(occurredOn: occurredOn, today: today);
  }

  /// RN-112: o vale só paga categoria elegível.
  static Failure? _voucherFailure(Category category, List<PaymentLine> lines) {
    final usesVoucher = lines.any((l) => l.tender == Tender.mealVoucher);
    if (!usesVoucher || category.voucherEligible) return null;
    return CategoryNotVoucherEligible(category.name);
  }
}
