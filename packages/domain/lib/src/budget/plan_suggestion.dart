import 'package:domain/src/budget/budget_line.dart';
import 'package:domain/src/budget/budget_plan.dart';
import 'package:domain/src/budget/line_group.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// "Minhas contas" sugeridas pelo que a pessoa já gastou.
///
/// O plano não é obrigatório. Depois de um mês usando o app sem plano, ele
/// propõe: "você gasta uns R$ 800 de mercado; quer usar isso?". Cada linha
/// arredonda para cima, de dez em dez reais: o "use o maior" da planilha.
@immutable
final class PlanSuggestion {
  /// Cria a sugestão.
  const new(this.lines);

  /// Quantos dias de uso antes de sugerir.
  static const daysOfUse = 30;

  /// As linhas sugeridas, da maior para a menor.
  final List<BudgetLine> lines;

  /// A sugestão para [today], ou `null` quando não cabe: o plano já tem
  /// contas, ou o app tem menos de um mês de uso.
  static PlanSuggestion? of({
    required BudgetPlan plan,
    required Iterable<Entry> entries,
    required Map<String, Category> categories,
    required LocalDate today,
    Iterable<Reversal> reversals = const [],
  }) {
    if (plan.lines.isNotEmpty || entries.isEmpty) return null;
    final first = entries
        .map((entry) => entry.occurredOn)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    if (first.daysUntil(today) < daysOfUse) return null;
    final spent = _lastMonth(entries, reversals, today);
    final lines = [
      for (final MapEntry(key: id, value: amount) in spent.entries)
        ?_line(categories[id], id, amount),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return lines.isEmpty ? null : PlanSuggestion(lines);
  }

  static Map<String, Money> _lastMonth(
    Iterable<Entry> entries,
    Iterable<Reversal> reversals,
    LocalDate today,
  ) {
    final from = today.addDays(-daysOfUse);
    bool inWindow(LocalDate on) => on.isAfter(from) && !on.isAfter(today);
    final spent = <String, Money>{};
    final categoryOf = <String, String>{};
    for (final entry in entries) {
      categoryOf[entry.id] = entry.categoryId;
      if (!inWindow(entry.occurredOn)) continue;
      final amounts = entry.spentIn(entry.occurredOn.budgetMonth);
      final id = entry.categoryId;
      spent[id] =
          (spent[id] ?? Money.zero) + amounts.cash + amounts.mealVoucher;
    }
    // A compra devolvida não vira conta sugerida (RN-209).
    for (final reversal in reversals.where((r) => inWindow(r.occurredOn))) {
      final id = categoryOf[reversal.entryId];
      if (id == null) continue;
      spent[id] = (spent[id] ?? Money.zero) - reversal.line.amount;
    }
    return spent;
  }

  static BudgetLine? _line(Category? category, String id, Money amount) {
    if (category == null || !amount.isPositive) return null;
    final group = LineGroup.of(category.block);
    if (group == null || category.block == Block.debt) return null;
    final roundedUp = Money.fromCents((amount.cents + 999) ~/ 1000 * 1000);
    return BudgetLine.create(
      id: 'sugerida-$id',
      name: category.name,
      amount: roundedUp,
      group: group,
      categoryId: id,
    ).valueOrNull;
  }
}
