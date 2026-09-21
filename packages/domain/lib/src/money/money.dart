import 'package:meta/meta.dart';

/// Um valor em reais, guardado como um inteiro de centavos (RN-101).
///
/// Não existe `double` no caminho de um valor, em nenhuma camada: ponto
/// flutuante não representa centavos com exatidão, e num app de dinheiro um
/// centavo errado é um defeito, não um arredondamento.
///
/// `Money` pode ser negativo — a sobra de um mês que não fechou é. O que nunca
/// é negativo é o valor de um lançamento, e quem garante isso é o lançamento
/// (RN-104), não este tipo.
@immutable
final class Money implements Comparable<Money> {
  /// Cria o valor a partir de centavos: `Money.fromCents(128450)` é
  /// R$ 1.284,50.
  const new fromCents(this.cents);

  /// O resultado de `value × numerator ÷ denominator`, arredondado para o
  /// centavo mais próximo, com meio centavo para cima (RN-103).
  factory ratio(Money value, int numerator, int denominator) {
    final scaled = value.cents * numerator;
    final doubled = 2 * scaled + denominator;
    return Money.fromCents(_floorDivide(doubled, 2 * denominator));
  }

  /// Como [Money.ratio], mas arredondando para **baixo**: é a regra dos
  /// limites de gasto, que nunca prometem um centavo que não existe (RN-103).
  factory ratioFloor(Money value, int numerator, int denominator) =>
      Money.fromCents(_floorDivide(value.cents * numerator, denominator));

  /// Nada.
  static const zero = Money.fromCents(0);

  /// O valor, em centavos.
  final int cents;

  /// Divisão inteira que arredonda para baixo também com número negativo —
  /// a do Dart (`~/`) arredonda em direção ao zero.
  static int _floorDivide(int numerator, int denominator) {
    assert(denominator > 0, 'O divisor precisa ser positivo.');
    final quotient = numerator ~/ denominator;
    final exact = numerator % denominator == 0;
    return exact || numerator >= 0 ? quotient : quotient - 1;
  }

  /// Maior que zero.
  bool get isPositive => cents > 0;

  /// Menor que zero.
  bool get isNegative => cents < 0;

  /// Exatamente zero.
  bool get isZero => cents == 0;

  /// A soma com [other].
  Money operator +(Money other) => Money.fromCents(cents + other.cents);

  /// A diferença para [other]. Pode ficar negativa.
  Money operator -(Money other) => Money.fromCents(cents - other.cents);

  /// O valor multiplicado por um número inteiro de vezes.
  Money operator *(int times) => Money.fromCents(cents * times);

  /// O sinal trocado.
  Money operator -() => Money.fromCents(-cents);

  /// Maior que [other].
  bool operator >(Money other) => cents > other.cents;

  /// Maior ou igual a [other].
  bool operator >=(Money other) => cents >= other.cents;

  /// Menor que [other].
  bool operator <(Money other) => cents < other.cents;

  /// Menor ou igual a [other].
  bool operator <=(Money other) => cents <= other.cents;

  /// Este valor, ou zero, se ele for negativo.
  Money get orZeroIfNegative => isNegative ? zero : this;

  /// Divide em [parts] partes cuja soma é exatamente este valor: o resto, em
  /// centavos, vai um a um para as primeiras partes (RN-102).
  ///
  /// R$ 100,00 em 3 dá 33,34 · 33,33 · 33,33.
  List<Money> split(int parts) {
    assert(parts > 0, 'Dividir pede ao menos uma parte.');
    assert(!isNegative, 'Só se divide valor que não é negativo.');
    final base = cents ~/ parts;
    final remainder = cents % parts;
    return [
      for (var i = 0; i < parts; i++)
        Money.fromCents(i < remainder ? base + 1 : base),
    ];
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  /// Para depuração e mensagem de teste. **Não é texto de tela**: quem
  /// formata real para a pessoa ler é o design system.
  @override
  String toString() => 'Money($cents)';
}
