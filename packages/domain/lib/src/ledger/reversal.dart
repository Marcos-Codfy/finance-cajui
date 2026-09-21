import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/payment_line.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// Um estorno: dinheiro de uma compra que voltou.
///
/// É um registro próprio, ligado ao lançamento original, que **não o altera**
/// (RN-208): reduz o gasto da categoria no mês da **data do estorno**
/// (RN-209) e volta pela mesma forma de pagamento da linha estornada
/// (RN-211) — estorno de compra no vale devolve saldo ao vale.
@immutable
final class Reversal {
  const new _({
    required this.id,
    required this.entryId,
    required this.line,
    required this.occurredOn,
  });

  /// O identificador do estorno.
  final String id;

  /// O lançamento que está sendo estornado.
  final String entryId;

  /// Por onde e quanto voltou: a mesma forma de pagamento da linha original.
  final PaymentLine line;

  /// O dia em que o dinheiro voltou; define o mês em que o estorno conta.
  final LocalDate occurredOn;

  /// Quanto já voltou pela forma de pagamento [paymentMethodId].
  static Money _reversedOn(
    String paymentMethodId,
    Iterable<Reversal> previous,
  ) {
    return previous
        .where((r) => r.line.paymentMethodId == paymentMethodId)
        .fold(Money.zero, (sum, r) => sum + r.line.amount);
  }

  /// Cria o estorno de [amount] na forma [paymentMethodId] do lançamento
  /// [entry], considerando os estornos [previous] que ele já teve.
  ///
  /// Recusa o que passar do que resta naquela linha (RN-210).
  static Result<Reversal> create({
    required String id,
    required Entry entry,
    required String paymentMethodId,
    required Money amount,
    required LocalDate occurredOn,
    Iterable<Reversal> previous = const [],
  }) {
    if (!amount.isPositive) return Err(NonPositiveAmount(amount));
    final original = entry.paymentLines.firstWhere(
      (line) => line.paymentMethodId == paymentMethodId,
    );
    final remaining = original.amount - _reversedOn(paymentMethodId, previous);
    if (amount > remaining) {
      return Err(
        ReversalExceedsRemaining(remaining: remaining, requested: amount),
      );
    }
    final line = PaymentLine(
      paymentMethodId: paymentMethodId,
      kind: original.kind,
      amount: amount,
    );
    return Ok(
      Reversal._(id: id, entryId: entry.id, line: line, occurredOn: occurredOn),
    );
  }
}
