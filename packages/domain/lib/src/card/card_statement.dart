import 'package:domain/src/card/statement_cycle.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/payment_line.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// A fatura de um cartão num ciclo — uma **visão calculada**, nunca um fato
/// gravado e nunca uma despesa (RN-330).
///
/// Fatura = compras à vista do ciclo + parcelas cobradas no ciclo − estornos
/// do ciclo. Juros, multa e anuidade entram como compras comuns, pagas com o
/// próprio cartão (RN-333). Apagar os lançamentos de um ciclo zera a fatura.
@immutable
final class CardStatement {
  /// Calcula a fatura do ciclo [cycle] a partir dos lançamentos e estornos.
  ///
  /// [legacyInstallments] soma as parcelas de compras anteriores ao uso do
  /// app, cadastradas como dívida do tipo `cardInstallment`.
  factory of(
    StatementCycle cycle, {
    required Iterable<Entry> entries,
    Iterable<Reversal> reversals = const [],
    Money legacyInstallments = Money.zero,
  }) {
    final byCategory = <String, Money>{};
    var installments = legacyInstallments;
    for (final entry in entries) {
      final upfront = _upfrontOn(cycle, entry);
      if (upfront.isPositive) {
        byCategory.update(
          entry.categoryId,
          (sum) => sum + upfront,
          ifAbsent: () => upfront,
        );
      }
      installments += _installmentOn(cycle, entry);
    }
    final reversed = reversals
        .where((r) => _isOnCard(cycle, r.line) && cycle.contains(r.occurredOn))
        .fold(Money.zero, (sum, r) => sum + r.line.amount);
    return CardStatement._(
      cycle,
      Map.unmodifiable(byCategory),
      installments,
      reversed,
    );
  }

  const new _(
    this.cycle,
    this.purchasesByCategory,
    this.installments,
    this.reversed,
  );

  /// O ciclo da fatura.
  final StatementCycle cycle;

  /// As compras à vista do ciclo, por categoria: é a composição que a tela
  /// da fatura mostra, agrupável por bloco (RN-331).
  final Map<String, Money> purchasesByCategory;

  /// As compras à vista feitas no ciclo.
  Money get purchases =>
      purchasesByCategory.values.fold(Money.zero, (sum, value) => sum + value);

  /// As parcelas cobradas nesta fatura.
  final Money installments;

  /// O que foi estornado no ciclo.
  final Money reversed;

  /// O total calculado da fatura.
  Money get total => purchases + installments - reversed;

  /// A diferença entre a fatura real, informada pela pessoa, e a calculada
  /// (RN-332): "R$ 60,00 ainda não identificados".
  ///
  /// Positiva quando falta lançar algo. O app **nunca** cria uma despesa de
  /// ajuste para fechar a conta: a diferença abre a busca pelo que falta.
  Money unidentifiedGiven(Money bankTotal) => bankTotal - total;

  static bool _isOnCard(StatementCycle cycle, PaymentLine line) =>
      line.kind.isCreditCard && line.paymentMethodId == cycle.cardId;

  /// A parcela de [entry] que esta fatura cobra, se houver.
  static Money _installmentOn(StatementCycle cycle, Entry entry) {
    final plan = entry.installmentPlan;
    if (plan == null || plan.cardId != cycle.cardId) return Money.zero;
    return plan.installmentDueIn(cycle.dueMonth)?.amount ?? Money.zero;
  }

  /// A parte de [entry] comprada à vista neste cartão, dentro do ciclo.
  static Money _upfrontOn(StatementCycle cycle, Entry entry) {
    if (!cycle.contains(entry.occurredOn)) return Money.zero;
    final parceled = entry.installmentPlan?.cardId == cycle.cardId;
    if (parceled) return Money.zero;
    return entry.paymentLines
        .where((line) => _isOnCard(cycle, line))
        .fold(Money.zero, (sum, line) => sum + line.amount);
  }
}
