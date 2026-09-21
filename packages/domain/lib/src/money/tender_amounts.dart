import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Um agregado por moeda: quanto em dinheiro, quanto em vale.
///
/// É o tipo de todo total do Cajui. **Não tem, de propósito, um total geral**:
/// a regra de nunca somar as duas moedas (RN-111) vira algo que o compilador
/// garante, em vez de algo de que alguém precisa se lembrar.
@immutable
final class TenderAmounts {
  /// Cria o agregado; o que não for informado é zero.
  const new({this.cash = Money.zero, this.mealVoucher = Money.zero});

  /// Um agregado só com [amount], na moeda [tender].
  factory single(Tender tender, Money amount) => switch (tender) {
    Tender.cash => TenderAmounts(cash: amount),
    Tender.mealVoucher => TenderAmounts(mealVoucher: amount),
  };

  /// Nada, em nenhuma moeda.
  static const zero = TenderAmounts();

  /// A parte em dinheiro.
  final Money cash;

  /// A parte em vale alimentação.
  final Money mealVoucher;

  /// A parte na moeda [tender].
  Money of(Tender tender) => switch (tender) {
    Tender.cash => cash,
    Tender.mealVoucher => mealVoucher,
  };

  /// A soma, moeda a moeda.
  TenderAmounts operator +(TenderAmounts other) => TenderAmounts(
    cash: cash + other.cash,
    mealVoucher: mealVoucher + other.mealVoucher,
  );

  /// A diferença, moeda a moeda.
  TenderAmounts operator -(TenderAmounts other) => TenderAmounts(
    cash: cash - other.cash,
    mealVoucher: mealVoucher - other.mealVoucher,
  );

  @override
  bool operator ==(Object other) =>
      other is TenderAmounts &&
      other.cash == cash &&
      other.mealVoucher == mealVoucher;

  @override
  int get hashCode => Object.hash(cash, mealVoucher);

  @override
  String toString() => 'TenderAmounts(cash: $cash, mealVoucher: $mealVoucher)';
}
