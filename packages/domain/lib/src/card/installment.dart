import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Uma parcela de uma compra parcelada no cartão.
@immutable
final class Installment {
  /// Cria a parcela [number] de um parcelamento.
  const new({
    required this.number,
    required this.amount,
    required this.dueMonth,
  });

  /// A posição da parcela, a partir de 1: "parcela 3 de 10".
  final int number;

  /// O valor da parcela.
  final Money amount;

  /// O mês em que **vence a fatura** que cobra esta parcela. É nele que a
  /// parcela conta (RN-311) — não no mês da compra.
  final BudgetMonth dueMonth;
}
