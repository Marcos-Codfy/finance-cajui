import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/debts/debt.dart';
import 'package:domain/src/debts/debt_kind.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money.dart';

/// O que vence de dívida num mês — o `D` das fórmulas (RN-504).
///
/// Junta duas origens que o plano trata igual: as dívidas cadastradas e as
/// parcelas das compras parceladas no cartão. Uma compra parcelada **é** uma
/// dívida sem juros (RN-503); o parcelamento mora no próprio lançamento, para
/// a parcela nunca ser contada duas vezes.
abstract final class DebtSchedule {
  /// O total das parcelas que vencem em [month].
  static Money dueIn(
    BudgetMonth month, {
    required Iterable<Debt> debts,
    Iterable<Entry> entries = const [],
  }) {
    final fromDebts = debts.fold(
      Money.zero,
      (sum, debt) => sum + debt.installmentDueIn(month),
    );
    final fromPurchases = entries.fold(
      Money.zero,
      (sum, entry) =>
          sum +
          (entry.installmentPlan?.installmentDueIn(month)?.amount ??
              Money.zero),
    );
    return fromDebts + fromPurchases;
  }

  /// As parcelas de [month] que o cartão [cardId] cobra por compras feitas
  /// antes do uso do app. Compõem a fatura (RN-330) sem virar lançamento
  /// novo (RN-521).
  static Money legacyCardInstallmentsDueIn(
    BudgetMonth month, {
    required String cardId,
    required Iterable<Debt> debts,
  }) => debts
      .where((d) => d.kind == DebtKind.cardInstallment && d.cardId == cardId)
      .fold(Money.zero, (sum, debt) => sum + debt.installmentDueIn(month));
}
