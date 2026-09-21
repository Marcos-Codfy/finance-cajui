import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// A faixa de um gasto variável: entre o mínimo e o máximo (RN-420).
///
/// O plano do mês usa sempre o **máximo** — o pior caso (RN-421). O mínimo é
/// o que a pessoa disse que não dá para cortar, e é ele que limita o quanto
/// um mês apertado pode ser ajustado.
@immutable
final class AmountRange {
  const new _(this.min, this.max);

  /// O menor gasto plausível no mês.
  final Money min;

  /// O maior gasto plausível: é o que entra no plano.
  final Money max;

  /// Quanto dá para cortar, do pior caso até o mínimo.
  Money get slack => max - min;

  /// Cria a faixa, recusando a que tiver mínimo negativo ou acima do máximo.
  static Result<AmountRange> create({required Money min, required Money max}) {
    if (min.isNegative || min > max) {
      return Err(RangeMinAboveMax(min: min, max: max));
    }
    return Ok(AmountRange._(min, max));
  }
}
