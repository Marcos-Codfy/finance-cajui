import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// Um remanejamento: mover folga de uma categoria para outra, num mês
/// (RN-403).
///
/// A folga de um bloco **não cobre sozinha** o que passou do plano em outro.
/// Cobrir é uma ação explícita de quem usa, registrada com origem, destino,
/// valor e mês — e aparece no fechamento. O app propõe; nunca faz por conta.
@immutable
final class Reallocation {
  const new _({
    required this.id,
    required this.month,
    required this.fromCategoryId,
    required this.toCategoryId,
    required this.amount,
  });

  /// O identificador do remanejamento.
  final String id;

  /// O mês em que vale.
  final BudgetMonth month;

  /// A categoria que cede a folga.
  final String fromCategoryId;

  /// A categoria que recebe.
  final String toCategoryId;

  /// Quanto foi movido.
  final Money amount;

  /// Cria o remanejamento, recusando o que passar da folga da origem.
  static Result<Reallocation> create({
    required String id,
    required BudgetMonth month,
    required String fromCategoryId,
    required String toCategoryId,
    required Money amount,
    required Money originSlack,
  }) {
    if (!amount.isPositive) return Err(NonPositiveAmount(amount));
    if (amount > originSlack) {
      return Err(
        ReallocationExceedsSlack(slack: originSlack, requested: amount),
      );
    }
    return Ok(
      Reallocation._(
        id: id,
        month: month,
        fromCategoryId: fromCategoryId,
        toCategoryId: toCategoryId,
        amount: amount,
      ),
    );
  }
}
