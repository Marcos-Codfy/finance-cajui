import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Uma fonte de renda do domicílio: salário, segunda renda, o crédito do vale
/// (RN-130).
///
/// Renda não é lançamento (RN-132): não existe categoria "salário", e renda e
/// despesa nunca se compensam dentro de uma categoria.
@immutable
final class IncomeSource {
  /// Cria a fonte. [inactiveFrom] nulo significa que ela continua ativa.
  const new({
    required this.id,
    required this.name,
    required this.tender,
    required this.expectedAmount,
    required this.expectedDay,
    this.inactiveFrom,
  });

  /// O identificador da fonte.
  final String id;

  /// O nome que a pessoa deu: "Salário".
  final String name;

  /// A moeda em que a renda chega.
  final Tender tender;

  /// O valor esperado por mês. É o que o plano usa enquanto o recebimento do
  /// mês não é registrado (RN-131).
  final Money expectedAmount;

  /// O dia do mês em que a renda costuma cair.
  final int expectedDay;

  /// O primeiro mês em que a fonte **deixa** de contar (RN-134). Os meses
  /// anteriores não mudam: desativar em novembro não mexe em outubro.
  final BudgetMonth? inactiveFrom;

  /// A fonte conta para o mês [month].
  bool isActiveIn(BudgetMonth month) {
    final end = inactiveFrom;
    return end == null || month.isBefore(end);
  }

  /// Se um recebimento de [amount] em [on] parece ser esta renda (RN-758):
  /// o valor difere do esperado em até 10%, e o dia fica a até 5 dias do
  /// esperado. "Pix recebido R$ 2.310,00 em 05/09" parece o salário de
  /// R$ 2.400 do dia 5; R$ 150,00 não parece.
  bool looksLike(Money amount, LocalDate on) {
    if (!isActiveIn(on.budgetMonth) || !expectedAmount.isPositive) {
      return false;
    }
    final gap = (amount.cents - expectedAmount.cents).abs();
    if (gap * 10 > expectedAmount.cents) return false;
    return _daysFromExpected(on) <= 5;
  }

  /// A distância até o dia esperado mais perto — o deste mês, o do anterior
  /// ou o do seguinte: o salário do dia 1 que cai no dia 30 está a dois dias,
  /// e não a vinte e nove.
  int _daysFromExpected(LocalDate on) {
    final month = on.budgetMonth;
    return [month.previous, month, month.next]
        .map((near) => on.daysUntil(near.dayClamped(expectedDay)).abs())
        .reduce((a, b) => a < b ? a : b);
  }
}
