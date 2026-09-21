import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/debts/debt_kind.dart';
import 'package:domain/src/debts/payoff_quote.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// Uma dívida: credor, parcela, quantas são e quantas já foram (RN-501).
///
/// O Cajui mostra dívida como fato e como distância a percorrer — "faltam 7
/// parcelas de R$ 212,00" —, nunca como bronca (RN-542). Os números que esta
/// classe entrega são os que a tela precisa para falar assim.
@immutable
final class Debt {
  const new _({
    required this.id,
    required this.creditor,
    required this.kind,
    required this.installmentAmount,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.dueDay,
    required this.firstMonth,
    this.cardId,
    this.payoffQuote,
  });

  /// O identificador da dívida.
  final String id;

  /// A quem se deve: "Empréstimo Banco X".
  final String creditor;

  /// O tipo da dívida.
  final DebtKind kind;

  /// O valor de cada parcela.
  final Money installmentAmount;

  /// Quantas parcelas são, ao todo.
  final int totalInstallments;

  /// Quantas já foram pagas.
  final int paidInstallments;

  /// O dia do vencimento.
  final int dueDay;

  /// O mês da primeira parcela.
  final BudgetMonth firstMonth;

  /// O cartão que cobra a parcela, quando a dívida é de cartão: é o que
  /// deixa uma compra anterior ao uso do app compor a fatura (RN-330).
  final String? cardId;

  /// O valor para quitar hoje, se a pessoa informou (RN-511).
  final PayoffQuote? payoffQuote;

  /// Quantas parcelas faltam.
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// O **saldo devedor nominal**: a soma das parcelas que faltam (RN-510).
  /// É o número padrão porque não depende de dado que a pessoa talvez não
  /// tenha.
  Money get outstandingBalance => installmentAmount * remainingInstallments;

  /// O que já foi pago — mostrado ao lado do que falta (RN-541).
  Money get paidSoFar => installmentAmount * paidInstallments;

  /// Quitada: as pagas igualaram o total (RN-530).
  bool get isPaidOff => remainingInstallments == 0;

  /// O mês da última parcela, no calendário atual. É sempre apresentado como
  /// projeção: "no ritmo atual, quita em abril de 2027" (RN-531).
  BudgetMonth get payoffForecast => firstMonth.addMonths(totalInstallments - 1);

  /// A parcela que entra no plano de [month], em dinheiro (RN-504). Zero
  /// fora do calendário da dívida: ela sai do plano no mês seguinte ao da
  /// última parcela (RN-532).
  Money installmentDueIn(BudgetMonth month) {
    final inCalendar =
        !month.isBefore(firstMonth) && !month.isAfter(payoffForecast);
    return inCalendar ? installmentAmount : Money.zero;
  }

  /// A dívida depois de mais uma parcela paga (RN-520).
  Debt withInstallmentPaid() {
    assert(!isPaidOff, 'Dívida quitada não tem parcela a pagar.');
    return _copy(paidInstallments: paidInstallments + 1);
  }

  /// A dívida com o valor para quitar informado pela pessoa.
  Debt withPayoffQuote(PayoffQuote quote) => _copy(payoffQuote: quote);

  Debt _copy({int? paidInstallments, PayoffQuote? payoffQuote}) => Debt._(
    id: id,
    creditor: creditor,
    kind: kind,
    installmentAmount: installmentAmount,
    totalInstallments: totalInstallments,
    paidInstallments: paidInstallments ?? this.paidInstallments,
    dueDay: dueDay,
    firstMonth: firstMonth,
    cardId: cardId,
    payoffQuote: payoffQuote ?? this.payoffQuote,
  );

  /// Cria a dívida, recusando parcela não positiva e mais pagas que o total.
  static Result<Debt> create({
    required String id,
    required String creditor,
    required DebtKind kind,
    required Money installmentAmount,
    required int totalInstallments,
    required int paidInstallments,
    required int dueDay,
    required BudgetMonth firstMonth,
    String? cardId,
  }) {
    return _validate(installmentAmount, totalInstallments, paidInstallments) ??
        Ok(
          Debt._(
            id: id,
            creditor: creditor,
            kind: kind,
            installmentAmount: installmentAmount,
            totalInstallments: totalInstallments,
            paidInstallments: paidInstallments,
            dueDay: dueDay,
            firstMonth: firstMonth,
            cardId: cardId,
          ),
        );
  }

  static Err<Debt>? _validate(Money installment, int total, int paid) {
    if (!installment.isPositive) return Err(NonPositiveAmount(installment));
    if (paid < 0 || paid > total) {
      return Err(PaidInstallmentsExceedTotal(total: total, paid: paid));
    }
    return null;
  }
}
