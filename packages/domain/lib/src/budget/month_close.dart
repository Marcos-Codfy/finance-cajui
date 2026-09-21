import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// O fechamento: o retrato **imutável** de um mês encerrado (RN-440).
///
/// Mudar uma faixa em outubro não altera o fechamento de setembro. Um
/// lançamento tardio gera uma **revisão** — a versão anterior é preservada, e
/// a diferença fica à vista (RN-441). A falta de um mês fechado não vira
/// dívida nem é descontada do mês seguinte por conta própria: é informada, e
/// o que fazer com ela é decisão de quem usa (RN-443).
@immutable
final class MonthClose {
  const new _({
    required this.month,
    required this.revision,
    required this.cashResult,
    required this.closedOn,
  });

  /// O mês fechado.
  final BudgetMonth month;

  /// A revisão do fechamento, a partir de 1.
  final int revision;

  /// O resultado em dinheiro: positivo é sobra; negativo, falta.
  final Money cashResult;

  /// Quando esta revisão foi feita.
  final LocalDate closedOn;

  /// Fecha [month] com o resultado [cashResult]. Só depois que o mês termina
  /// (RN-442): fechar setembro em 28/09 é recusado.
  static Result<MonthClose> close({
    required BudgetMonth month,
    required Money cashResult,
    required LocalDate today,
  }) {
    final closableFrom = month.next.firstDay;
    if (today.isBefore(closableFrom)) {
      return Err(MonthNotOver(month: month, closableFrom: closableFrom));
    }
    return Ok(
      MonthClose._(
        month: month,
        revision: 1,
        cashResult: cashResult,
        closedOn: today,
      ),
    );
  }

  /// A revisão seguinte, depois de um lançamento tardio. Esta continua
  /// existindo: quem guarda as duas é o registro de eventos.
  MonthClose revisedWith({required Money cashResult, required LocalDate on}) =>
      MonthClose._(
        month: month,
        revision: revision + 1,
        cashResult: cashResult,
        closedOn: on,
      );

  /// Quanto esta revisão mudou o resultado em relação a [previous]:
  /// "− R$ 42,00 em relação à revisão 1".
  Money differenceFrom(MonthClose previous) =>
      cashResult - previous.cashResult;
}
