import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/debts/debt_calendar.dart';
import 'package:domain/src/debts/debt_kind.dart';
import 'package:domain/src/debts/debt_type.dart';
import 'package:domain/src/debts/payoff_quote.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/edit_stamp.dart';
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
    this.informedBalance,
    this.informedOn,
    this.note,
    this.definedAt,
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

  /// O saldo que a pessoa informou, para a dívida que não se mede em
  /// parcelas — a conta atrasada, o rotativo. Nulo na dívida parcelada,
  /// cujo saldo é a soma das parcelas que faltam.
  final Money? informedBalance;

  /// O dia em que [informedBalance] valia.
  final LocalDate? informedOn;

  /// A observação da planilha: "negociar à vista com desconto".
  final String? note;

  /// Quando esta versão foi definida, em UTC (ADR-024). Dois celulares que
  /// mudam a mesma dívida ficam com a mais nova; sem carimbo — as gravadas
  /// antes dele —, a versão conta como a mais velha.
  final DateTime? definedAt;

  /// Se esta versão é mais nova que [other], pelo carimbo.
  bool isNewerThan(Debt other) => EditStamp.isNewer(definedAt, other.definedAt);

  /// Parcelado, atrasado ou rotativo: os três tipos da planilha.
  DebtType get type => DebtType.of(kind);

  /// Quantas parcelas faltam.
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// O **saldo devedor nominal**: a soma das parcelas que faltam (RN-510).
  /// É o número padrão porque não depende de dado que a pessoa talvez não
  /// tenha.
  Money get outstandingBalance =>
      informedBalance ?? installmentAmount * remainingInstallments;

  /// O que já foi pago — mostrado ao lado do que falta (RN-541).
  Money get paidSoFar => installmentAmount * paidInstallments;

  /// Quitada: as pagas igualaram o total (RN-530), ou o saldo informado
  /// chegou a zero.
  bool get isPaidOff => informedBalance?.isZero ?? remainingInstallments == 0;

  /// O mês da última parcela, no calendário atual. É sempre apresentado como
  /// projeção: "no ritmo atual, quita em abril de 2027" (RN-531). Na dívida
  /// de saldo informado, a primeira parcela é o primeiro vencimento depois
  /// do dia informado: informado no dia 11 com vencimento no 10, o do mês
  /// já passou.
  BudgetMonth get payoffForecast {
    final since = informedOn;
    final dueThisMonth = firstMonth.dayClamped(dueDay);
    final first = since != null && !dueThisMonth.isAfter(since)
        ? firstMonth.next
        : firstMonth;
    return first.addMonths(totalInstallments - 1);
  }

  /// A parcela que entra no plano de [month], em dinheiro (RN-504). Zero
  /// fora do calendário da dívida: ela sai do plano no mês seguinte ao da
  /// última parcela (RN-532).
  Money installmentDueIn(BudgetMonth month) {
    if (informedBalance != null) return DebtCalendar.balanceDueIn(this, month);
    final inCalendar =
        !month.isBefore(firstMonth) && !month.isAfter(payoffForecast);
    return inCalendar ? installmentAmount : Money.zero;
  }

  /// A dívida depois de mais uma parcela paga (RN-520).
  Debt withInstallmentPaid() {
    assert(!isPaidOff, 'Dívida quitada não tem parcela a pagar.');
    return _copy(paidInstallments: paidInstallments + 1);
  }

  /// A dívida depois que o pagamento de uma parcela foi cancelado (RN-208):
  /// o lançamento saiu de toda visão, e a parcela volta a estar em aberto.
  Debt withInstallmentReverted() {
    assert(paidInstallments > 0, 'Não há parcela paga para desfazer.');
    return _copy(paidInstallments: paidInstallments - 1);
  }

  /// A dívida com o valor para quitar informado pela pessoa.
  Debt withPayoffQuote(PayoffQuote quote) => _copy(payoffQuote: quote);

  /// A mesma dívida com [count] parcelas pagas: a dívida "como está hoje",
  /// quando o calendário já venceu mais parcelas do que o cadastro dizia.
  Debt withPaidInstallments(int count) => _copy(paidInstallments: count);

  /// Esta versão carimbada em [at].
  Debt stamped(DateTime at) => _copy(definedAt: at);

  /// Esta versão com o cartão e o valor para quitar de [previous]: atualizar
  /// o saldo depois de negociar não os perde.
  Debt keepingFrom(Debt previous) =>
      _copy(cardId: previous.cardId, payoffQuote: previous.payoffQuote);

  /// Esta versão cobrada no cartão [cardId], quando houver.
  Debt withCard(String? cardId) => _copy(cardId: cardId);

  Debt _copy({
    int? paidInstallments,
    PayoffQuote? payoffQuote,
    DateTime? definedAt,
    String? cardId,
  }) => Debt._(
    id: id,
    creditor: creditor,
    kind: kind,
    installmentAmount: installmentAmount,
    totalInstallments: totalInstallments,
    paidInstallments: paidInstallments ?? this.paidInstallments,
    dueDay: dueDay,
    firstMonth: firstMonth,
    cardId: cardId ?? this.cardId,
    payoffQuote: payoffQuote ?? this.payoffQuote,
    informedBalance: informedBalance,
    informedOn: informedOn,
    note: note,
    definedAt: definedAt ?? this.definedAt,
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
    String? note,
    DateTime? definedAt,
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
            note: note,
            definedAt: definedAt,
          ),
        );
  }

  /// Cria a dívida que se mede pelo saldo — a conta atrasada, o rotativo,
  /// o carnê de que não se sabe quantas parcelas faltam. [monthlyPayment]
  /// pode ser zero: "não pago nada por mês ainda". O saldo cai sozinho a
  /// cada vencimento depois de [informedOn] (ver `DebtCalendar`).
  static Result<Debt> withBalance({
    required String id,
    required String creditor,
    required DebtKind kind,
    required Money balance,
    required Money monthlyPayment,
    required int dueDay,
    required LocalDate informedOn,
    String? note,
    DateTime? definedAt,
  }) {
    final negative = _negative([balance, monthlyPayment]);
    if (negative != null) return Err(NonPositiveAmount(negative));
    return Ok(
      Debt._(
        id: id,
        creditor: creditor,
        kind: kind,
        installmentAmount: monthlyPayment,
        totalInstallments: _installmentsFor(balance, monthlyPayment),
        paidInstallments: 0,
        dueDay: dueDay,
        firstMonth: informedOn.budgetMonth,
        informedBalance: balance,
        informedOn: informedOn,
        note: note,
        definedAt: definedAt,
      ),
    );
  }

  static Money? _negative(List<Money> amounts) =>
      amounts.where((amount) => amount.isNegative).firstOrNull;

  /// Quantas parcelas quitam [balance], para a previsão de quando acaba.
  static int _installmentsFor(Money balance, Money payment) {
    if (!payment.isPositive) return 0;
    return (balance.cents + payment.cents - 1) ~/ payment.cents;
  }

  static Err<Debt>? _validate(Money installment, int total, int paid) {
    if (!installment.isPositive) return Err(NonPositiveAmount(installment));
    if (paid < 0 || paid > total) {
      return Err(PaidInstallmentsExceedTotal(total: total, paid: paid));
    }
    return null;
  }
}
