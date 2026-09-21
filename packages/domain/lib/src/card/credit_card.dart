import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// Um cartão de crédito: uma **forma de pagamento** com ciclo de fatura
/// (RN-301 e RN-302). Não é categoria, não é bloco, não é despesa.
@immutable
final class CreditCard {
  const new _({
    required this.id,
    required this.name,
    required this.closingDay,
    required this.dueDay,
    this.creditLimit,
  });

  /// O identificador; é também o da forma de pagamento nas linhas.
  final String id;

  /// O apelido do cartão: "Cartão final 4821".
  final String name;

  /// O dia em que a fatura fecha — o **primeiro dia do ciclo novo** (RN-303).
  final int closingDay;

  /// O dia em que a fatura vence.
  final int dueDay;

  /// O limite de crédito, se a pessoa quiser informar.
  final Money? creditLimit;

  /// Cria o cartão, recusando dia fora de 1 a 31.
  ///
  /// Dia 31 é aceito: nos meses mais curtos, vale o último dia do mês.
  static Result<CreditCard> create({
    required String id,
    required String name,
    required int closingDay,
    required int dueDay,
    Money? creditLimit,
  }) {
    for (final day in [closingDay, dueDay]) {
      if (day < 1 || day > 31) return Err(InvalidCardDay(day));
    }
    return Ok(
      CreditCard._(
        id: id,
        name: name,
        closingDay: closingDay,
        dueDay: dueDay,
        creditLimit: creditLimit,
      ),
    );
  }
}
