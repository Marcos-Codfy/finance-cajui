import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Um gasto de rotina, com a data em que aconteceu.
typedef DatedSpend = ({LocalDate on, Money amount});

/// O gasto **variável, em dinheiro**, de um mês — separado em rotina e fora
/// do padrão.
///
/// A separação é a RN-648: o conserto de R$ 700 conta inteiro no resultado do
/// mês, e aparece à parte da rotina, onde pode ser resolvido — em "quanto
/// falta ajustar".
@immutable
final class MonthSpending {
  /// Soma o que conta em [month]: linha em dinheiro, de categoria do bloco
  /// variável, pela data da compra — inclusive compra à vista no cartão
  /// (RN-643). Vale, fixos, dívidas e parcelas ficam de fora.
  factory of(
    BudgetMonth month, {
    required Iterable<Entry> entries,
    required Map<String, Category> categories,
    Iterable<Reversal> reversals = const [],
  }) {
    final routine = <DatedSpend>[];
    final byCategory = <String, Money>{};
    var exceptional = Money.zero;
    for (final entry in entries) {
      final cash = entry.spentIn(month).cash;
      final variable = categories[entry.categoryId]?.block == Block.variable;
      if (!variable || !cash.isPositive) continue;
      if (entry.isExceptional) {
        exceptional += cash;
        continue;
      }
      routine.add((on: entry.occurredOn, amount: cash));
      _add(byCategory, entry.categoryId, cash);
    }
    _applyReversals(month, reversals, entries, categories, routine, byCategory);
    return MonthSpending._(
      List.unmodifiable(routine),
      Map.unmodifiable(byCategory),
      exceptional,
    );
  }

  const new _(this.routine, this.routineByCategory, this.exceptional);

  /// Os gastos de rotina, um a um, com data. Estorno entra negativo.
  final List<DatedSpend> routine;

  /// O gasto de rotina de cada categoria.
  final Map<String, Money> routineByCategory;

  /// O total dos gastos fora do padrão do mês (RN-240). Compra parcelada
  /// fica de fora daqui, marcada ou não: ela conta parcela a parcela, em
  /// dívidas (RN-242, RN-312).
  final Money exceptional;

  /// O gasto de rotina feito **antes** de [day], no mês (RN-646).
  Money routineBefore(LocalDate day) => _sum((s) => s.on.isBefore(day));

  /// O gasto de rotina entre [start] e [end], inclusive.
  Money routineBetween(LocalDate start, LocalDate end) =>
      _sum((s) => !s.on.isBefore(start) && !s.on.isAfter(end));

  Money _sum(bool Function(DatedSpend) test) =>
      routine.where(test).fold(Money.zero, (sum, s) => sum + s.amount);

  static void _add(Map<String, Money> totals, String key, Money amount) =>
      totals.update(key, (sum) => sum + amount, ifAbsent: () => amount);

  /// O estorno reduz o gasto da categoria no mês da **data do estorno**
  /// (RN-209), e só quando voltou em dinheiro.
  static void _applyReversals(
    BudgetMonth month,
    Iterable<Reversal> reversals,
    Iterable<Entry> entries,
    Map<String, Category> categories,
    List<DatedSpend> routine,
    Map<String, Money> byCategory,
  ) {
    final byId = {for (final entry in entries) entry.id: entry};
    for (final reversal in reversals) {
      final entry = byId[reversal.entryId];
      final counts =
          entry != null &&
          !entry.isExceptional &&
          month.contains(reversal.occurredOn) &&
          reversal.line.tender == Tender.cash &&
          categories[entry.categoryId]?.block == Block.variable;
      if (!counts) continue;
      routine.add((on: reversal.occurredOn, amount: -reversal.line.amount));
      _add(byCategory, entry.categoryId, -reversal.line.amount);
    }
  }
}
