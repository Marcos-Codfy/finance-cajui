import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_text.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';

/// Um erro pronto para a tela: o código do catálogo e o texto já com os
/// valores no lugar das chaves.
typedef PresentedError = ({ErrorCode code, ErrorText text});

/// Transforma a recusa de uma regra no que a pessoa lê (ADR-015).
///
/// O código vem do mesmo `FailureMapper` que o servidor usa; o texto, do
/// catálogo. Aqui só se decide como cada valor aparece: dinheiro no formato
/// da casa, data por extenso.
abstract final class FailurePresenter {
  /// O erro de [failure]. [names] traz o que a falha não carrega e só a tela
  /// sabe — o nome da segunda forma de pagamento, o da categoria de origem.
  static PresentedError present(
    Failure failure, {
    Map<String, String> names = const {},
  }) {
    final (code, _) = FailureMapper.map(failure);
    final values = {..._values(failure), ...names};
    return (code: code, text: ErrorTexts.of(code).fill(values));
  }

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  static String _capitalized(String text) =>
      text[0].toUpperCase() + text.substring(1);

  static Map<String, String> _values(Failure failure) => switch (failure) {
    EntryFailure() => _entry(failure),
    VoucherFailure() => _voucher(failure),
    CardFailure() => _card(failure),
    BudgetFailure() => _budget(failure),
    DebtFailure() => _debt(failure),
  };

  static Map<String, String> _entry(EntryFailure failure) => switch (failure) {
    PaymentLinesMismatch(:final amount, :final linesTotal) => {
      'soma': _brl(linesTotal),
      'valor': _brl(amount),
      'diferença': _brl(
        amount > linesTotal ? amount - linesTotal : linesTotal - amount,
      ),
    },
    PurchaseDateInFuture() ||
    NonPositiveAmount() ||
    EntryNoLongerExists() => const {},
    ReversalExceedsRemaining(:final remaining, :final requested) => {
      'restante': _brl(remaining),
      'pedido': _brl(requested),
    },
  };

  static Map<String, String> _voucher(VoucherFailure failure) {
    return switch (failure) {
      VoucherBalanceExceeded(:final balance, :final requested) => {
        'saldo': _brl(balance),
        'valor': _brl(requested),
      },
      CategoryNotVoucherEligible(:final categoryName) => {
        'categoria': categoryName,
      },
    };
  }

  static Map<String, String> _card(CardFailure failure) => switch (failure) {
    InvalidCardDay() => const {},
    CategoryRepresentsCard(:final name) => {'nome': name},
  };

  static Map<String, String> _budget(BudgetFailure failure) {
    return switch (failure) {
      RangeMinAboveMax(:final min, :final max) => {
        'mínimo': _brl(min),
        'máximo': _brl(max),
      },
      MonthNotOver(:final month, :final closableFrom) => {
        // O mês abre a frase do catálogo, então vai com inicial maiúscula.
        'mês': _capitalized(DateLabels.month(month)),
        'data': DateLabels.long(closableFrom),
      },
      AdjustmentBelowMinimum(:final minimum, :final result) => {
        'mínimo': _brl(minimum),
        'resultado': _brl(result),
      },
      ReallocationExceedsSlack(:final slack, :final requested) => {
        'folga': _brl(slack),
        'pedido': _brl(requested),
      },
    };
  }

  static Map<String, String> _debt(DebtFailure failure) => switch (failure) {
    PaidInstallmentsExceedTotal(:final total, :final paid) => {
      'total': '$total',
      'pagas': '$paid',
    },
  };
}
