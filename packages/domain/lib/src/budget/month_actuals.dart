import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';

/// O que foi gasto de verdade em cada categoria, num mês, somando as duas
/// moedas.
///
/// Somar dinheiro e vale aqui não é misturar as moedas (RN-111): a planilha
/// conta o mercado inteiro em "o que sai" e depois tira o que o vale cobre.
/// A separação está no fim da conta, em `MonthBudget`, e não no meio.
///
/// A compra parcelada no cartão entra só pela parte à vista: as parcelas
/// vêm da dívida (RN-312). O estorno abate a categoria do lançamento, no mês
/// em que aconteceu.
abstract final class MonthActuals {
  /// O gasto por categoria em [month]. [excluded] tira lançamentos que já
  /// contam por outro caminho — o pagamento de parcela ligado a uma dívida,
  /// que entra pela dívida e não pode contar duas vezes.
  static Map<String, Money> byCategory(
    BudgetMonth month, {
    required Iterable<Entry> entries,
    Iterable<Reversal> reversals = const [],
    Set<String> excluded = const {},
  }) {
    final spent = <String, Money>{};
    final categoryOf = <String, String>{};
    for (final entry in entries) {
      categoryOf[entry.id] = entry.categoryId;
      if (excluded.contains(entry.id)) continue;
      final amounts = entry.spentIn(month);
      _add(spent, entry.categoryId, amounts.cash + amounts.mealVoucher);
    }
    for (final reversal in reversals) {
      final category = categoryOf[reversal.entryId];
      if (category == null || excluded.contains(reversal.entryId)) continue;
      if (reversal.occurredOn.budgetMonth != month) continue;
      _add(spent, category, -reversal.line.amount);
    }
    return spent;
  }

  static void _add(Map<String, Money> spent, String category, Money amount) {
    if (amount.isZero) return;
    spent[category] = (spent[category] ?? Money.zero) + amount;
  }
}
