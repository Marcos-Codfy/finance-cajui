import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O acumulado dos gastos fora do padrão de um ano (RN-240 e RN-241).
///
/// Cada gasto que "não se repete" parece exceção quando visto sozinho. Somados
/// entre categorias e divididos pelos meses do ano, eles viram um número que
/// se repete — e é esse número que o app mostra ao marcar o próximo.
@immutable
final class ExceptionalSpending {
  /// Soma os lançamentos fora do padrão de [entries] no ano de [upTo], até o
  /// mês [upTo], inclusive.
  factory of(Iterable<Entry> entries, {required BudgetMonth upTo}) {
    final counted = entries.where(
      (entry) =>
          entry.isExceptional &&
          entry.occurredOn.year == upTo.year &&
          !entry.occurredOn.budgetMonth.isAfter(upTo),
    );
    var total = Money.zero;
    var count = 0;
    for (final entry in counted) {
      // Só a parte em dinheiro: o acumulado é um número só, e dinheiro e vale
      // nunca se somam (RN-111).
      total += entry.paidByTender.cash;
      count++;
    }
    return ExceptionalSpending._(count: count, total: total, months: upTo.month);
  }

  const new _({required this.count, required this.total, required this.months});

  /// Quantos gastos fora do padrão houve no ano: "4º gasto do ano".
  final int count;

  /// Quanto somam, em dinheiro.
  final Money total;

  /// Quantos meses do ano já passaram, contando o atual.
  final int months;

  /// A média por mês do ano até aqui: o "fora do padrão" que, na prática, é
  /// padrão.
  Money get monthlyAverage => Money.ratio(total, 1, months);
}
