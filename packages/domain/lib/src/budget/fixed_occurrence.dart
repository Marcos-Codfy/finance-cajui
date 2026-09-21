import 'package:domain/src/budget/fixed_expense.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// A ocorrência de um fixo num mês: o aluguel **de setembro**.
@immutable
final class FixedOccurrence {
  /// A ocorrência de [expense] em [month]. [paidAmount] é o valor do
  /// lançamento ligado a ela, quando já houve pagamento.
  const new({required this.expense, required this.month, this.paidAmount});

  /// O fixo a que a ocorrência pertence.
  final FixedExpense expense;

  /// O mês da ocorrência.
  final BudgetMonth month;

  /// O que foi pago de fato, se já foi.
  final Money? paidAmount;

  /// Já há lançamento ligado a esta ocorrência.
  bool get isPaid => paidAmount != null;

  /// O valor com que o mês calcula: o pago, se houver; senão, o esperado
  /// (RN-411). Internet esperada em R$ 100,00 e paga em R$ 104,90: o mês usa
  /// R$ 104,90.
  Money get amount => paidAmount ?? expense.amount;

  /// O dia do vencimento neste mês.
  LocalDate get dueOn => month.dayClamped(expense.dueDay);

  /// Venceu e ainda não tem lançamento: "em aberto desde 10/09" (RN-414).
  ///
  /// O app não calcula multa nem juros por conta própria: quem informa o que
  /// pagou é a pessoa.
  bool isOverdueOn(LocalDate today) => !isPaid && today.isAfter(dueOn);
}
