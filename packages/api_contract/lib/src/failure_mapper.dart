import 'package:api_contract/src/error_code.dart';
import 'package:domain/domain.dart';

/// O código do catálogo e os valores que o texto do erro usa.
typedef MappedFailure = (ErrorCode, Map<String, Object?>);

/// Traduz uma recusa do domínio em erro do catálogo (ADR-015).
///
/// Mora no contrato, e não no servidor, porque os dois lados precisam dela: o
/// servidor para montar o corpo de erro, e o app para chegar ao mesmo texto
/// quando a regra é recusada **no aparelho**, sem rede.
///
/// Cada `switch` é **exaustivo** sobre uma família selada de `Failure`, e não
/// há caso curinga: criar uma falha nova no domínio sem dizer aqui que código
/// ela tem não compila. É este arquivo que impede o erro genérico de nascer.
abstract final class FailureMapper {
  /// O código e o detalhe de [failure].
  static MappedFailure map(Failure failure) => switch (failure) {
    EntryFailure() => _entry(failure),
    VoucherFailure() => _voucher(failure),
    CardFailure() => _card(failure),
    BudgetFailure() => _budget(failure),
    DebtFailure() => _debt(failure),
  };

  static MappedFailure _entry(EntryFailure failure) => switch (failure) {
    PaymentLinesMismatch(:final amount, :final linesTotal) => (
      ErrorCode.entry01,
      {'amountCents': amount.cents, 'linesTotalCents': linesTotal.cents},
    ),
    PurchaseDateInFuture(:final occurredOn, :final today) => (
      ErrorCode.entry02,
      {'occurredOn': '$occurredOn', 'today': '$today'},
    ),
    NonPositiveAmount(:final amount) => (
      ErrorCode.entry03,
      {'amountCents': amount.cents},
    ),
    ReversalExceedsRemaining(:final remaining, :final requested) => (
      ErrorCode.entry04,
      {'remainingCents': remaining.cents, 'requestedCents': requested.cents},
    ),
  };

  static MappedFailure _voucher(VoucherFailure failure) => switch (failure) {
    VoucherBalanceExceeded(:final balance, :final requested) => (
      ErrorCode.voucher01,
      {'balanceCents': balance.cents, 'requestedCents': requested.cents},
    ),
    CategoryNotVoucherEligible(:final categoryName) => (
      ErrorCode.voucher02,
      {'category': categoryName},
    ),
  };

  static MappedFailure _card(CardFailure failure) => switch (failure) {
    InvalidCardDay(:final day) => (ErrorCode.card01, {'day': day}),
    CategoryRepresentsCard(:final name) => (ErrorCode.card02, {'name': name}),
  };

  static MappedFailure _budget(BudgetFailure failure) => switch (failure) {
    RangeMinAboveMax(:final min, :final max) => (
      ErrorCode.budg01,
      {'minCents': min.cents, 'maxCents': max.cents},
    ),
    MonthNotOver(:final month, :final closableFrom) => (
      ErrorCode.budg02,
      {'month': '$month', 'closableFrom': '$closableFrom'},
    ),
    AdjustmentBelowMinimum(:final categoryId, :final minimum, :final result) =>
      (
        ErrorCode.budg03,
        {
          'categoryId': categoryId,
          'minimumCents': minimum.cents,
          'resultCents': result.cents,
        },
      ),
    ReallocationExceedsSlack(:final slack, :final requested) => (
      ErrorCode.budg04,
      {'slackCents': slack.cents, 'requestedCents': requested.cents},
    ),
  };

  static MappedFailure _debt(DebtFailure failure) => switch (failure) {
    PaidInstallmentsExceedTotal(:final total, :final paid) => (
      ErrorCode.debt01,
      {'total': total, 'paid': paid},
    ),
  };
}
