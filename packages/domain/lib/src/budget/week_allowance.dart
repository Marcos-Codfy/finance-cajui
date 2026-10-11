import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/indicators/percent.dart';
import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// A semana: quanto dá para gastar, quanto já foi e quanto resta.
///
/// O limite é o da planilha — o que sobra do mês depois do que é certo,
/// dividido por quatro. O gasto é o do dia a dia desde segunda-feira (ou
/// desde o dia 1, se o mês começou no meio da semana), nas duas moedas,
/// porque o limite também conta o que o vale cobre.
@immutable
final class WeekAllowance {
  /// Cria a semana.
  const new({required this.limit, required this.spent, required this.from});

  /// A semana de [today], com o limite [limit].
  factory of({
    required Money limit,
    required LocalDate today,
    required Iterable<Entry> entries,
    required Map<String, Category> categories,
    Set<String> excluded = const {},
  }) {
    final from = startOf(today);
    var spent = Money.zero;
    for (final entry in entries) {
      final on = entry.occurredOn;
      if (on.isBefore(from) || on.isAfter(today)) continue;
      if (excluded.contains(entry.id)) continue;
      if (!_isDayToDay(categories[entry.categoryId])) continue;
      final amounts = entry.spentIn(on.budgetMonth);
      spent += amounts.cash + amounts.mealVoucher;
    }
    return WeekAllowance(limit: limit, spent: spent, from: from);
  }

  /// O primeiro dia da semana de [today]: segunda-feira, ou o dia 1.
  static LocalDate startOf(LocalDate today) {
    final monday = today.addDays(1 - today.weekday);
    final first = today.budgetMonth.firstDay;
    return monday.isBefore(first) ? first : monday;
  }

  /// Juros e tarifas contam no mês, mas não na semana: não são escolha de
  /// gasto, e fariam o pote parecer vazio por algo que ninguém comprou.
  static bool _isDayToDay(Category? category) =>
      (category?.block ?? Block.variable) == Block.variable;

  /// Quanto dá para gastar na semana.
  final Money limit;

  /// Quanto do dia a dia já saiu na semana.
  final Money spent;

  /// O primeiro dia da semana contada.
  final LocalDate from;

  /// A mesma semana com mais [amount] gasto: o "antes e depois" de uma
  /// compra que ainda vai ser lançada.
  WeekAllowance withSpending(Money amount) =>
      WeekAllowance(limit: limit, spent: spent + amount, from: from);

  /// O último dia da semana: o domingo, sem passar do fim do mês.
  LocalDate get until {
    final sunday = from.addDays(7 - from.weekday);
    final last = from.budgetMonth.lastDay;
    return sunday.isAfter(last) ? last : sunday;
  }

  /// Se [day] cai nesta semana: de [from] até [until].
  bool contains(LocalDate day) => !day.isBefore(from) && !day.isAfter(until);

  /// Quanto resta; zero quando já passou.
  Money get left => (limit - spent).orZeroIfNegative;

  /// Quanto passou do limite; zero quando não passou.
  Money get over => (spent - limit).orZeroIfNegative;

  /// O que resta, em percentual inteiro do limite — é o nível do pote.
  int get leftPercent {
    final percent = Percent.of(left, limit) ?? 0;
    return percent > 100 ? 100 : percent;
  }
}
