import 'package:domain/src/debts/debt.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// "E se eu pagar R$ 100 a mais por mês?" (RN-533)
///
/// A conta é determinística e feita sobre o **saldo nominal**, sem juros —
/// e o resultado diz isso, para ninguém tomar a simulação por promessa do
/// credor. Não é a IA que calcula: ela só apresenta este número.
@immutable
final class PayoffSimulation {
  /// Simula pagar [extraPerMonth] além da parcela de [debt].
  factory withExtra(Debt debt, Money extraPerMonth) {
    final perMonth = debt.installmentAmount + extraPerMonth;
    final balance = debt.outstandingBalance;
    final months = (balance.cents + perMonth.cents - 1) ~/ perMonth.cents;
    return PayoffSimulation._(
      monthsToPayoff: months,
      monthsSaved: debt.remainingInstallments - months,
    );
  }

  const new _({required this.monthsToPayoff, required this.monthsSaved});

  /// A base do cálculo, para o texto da resposta: sempre o saldo nominal.
  static const basis = 'nominal';

  /// Em quantos meses a dívida termina, no novo ritmo.
  final int monthsToPayoff;

  /// Quantos meses a menos que no ritmo atual.
  final int monthsSaved;
}
