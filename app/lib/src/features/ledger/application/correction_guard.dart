import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// O que pode impedir uma correção de valer.
///
/// Corrigir passa pelas mesmas regras de lançar, e por mais duas que só
/// existem porque o lançamento já tem história: o vale já tinha pago uma
/// parte, e a compra pode já ter tido estorno.
abstract final class CorrectionGuard {
  /// A falha que impede [next] de valer no lugar de [original] em [book], ou
  /// `null` quando pode: o vale não cobre a parte nova (RN-122), ou já voltou
  /// por estorno mais do que a linha corrigida paga (RN-210).
  static Failure? refusalOf(LedgerBook book, Entry original, Entry next) {
    final before = original.paidByTender.mealVoucher;
    final after = next.paidByTender.mealVoucher;
    // Só o que a correção põe **a mais** no vale precisa de saldo. Tirar
    // do vale, ou deixar como está, sempre pode — inclusive com a conta a
    // descoberto, que é justamente quando corrigir é o conserto (RN-124).
    if (after > before) {
      final paid = book.voucher.reverse(before).pay(after);
      if (paid.failureOrNull case final failure?) return failure;
    }
    for (final reversal in book.reversedOf(original.id)) {
      final back = reversal.line.amount;
      final remaining = book.reversibleOn(next, reversal.line.paymentMethodId);
      if (remaining.isNegative) {
        return ReversalExceedsRemaining(
          remaining: remaining + back,
          requested: back,
        );
      }
    }
    return null;
  }
}
