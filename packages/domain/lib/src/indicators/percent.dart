import 'package:domain/src/money/money.dart';

/// Proporções sobre a renda, como percentual inteiro.
abstract final class Percent {
  /// Quanto [part] representa de [whole], em percentual inteiro, com meio
  /// ponto para cima (RN-632): 51,94% vira 52.
  ///
  /// Devolve **nulo** quando [whole] é zero ou negativo: a proporção é
  /// indefinida, e o app pede a renda em vez de mostrar 0%, infinito ou
  /// "NaN%" (RN-604).
  static int? of(Money part, Money whole) {
    if (!whole.isPositive) return null;
    return (2 * 100 * part.cents + whole.cents) ~/ (2 * whole.cents);
  }
}
