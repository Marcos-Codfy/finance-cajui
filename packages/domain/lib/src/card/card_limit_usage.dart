import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/card/card_statement.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/card/settlement.dart';
import 'package:domain/src/card/statement_cycle.dart';
import 'package:domain/src/debts/debt.dart';
import 'package:domain/src/debts/debt_kind.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Quanto do limite de um cartão está **tomado** (RN-305).
///
/// Tomado é tudo o que foi comprado no cartão e ainda não foi pago: o que
/// resta das faturas ainda não liquidadas, mais as parcelas que ainda vão
/// vencer. É a conta que o banco faz — compra parcelada toma o limite pelo
/// valor inteiro e o devolve parcela a parcela, conforme as faturas são
/// pagas —, para o número daqui bater com o do aplicativo do banco.
///
/// Como a fatura, é uma **visão calculada**: nada aqui é gravado, e nada
/// aqui é despesa.
@immutable
final class CardLimitUsage {
  const new _({required this.limit, required this.taken});

  /// O uso do limite de [card] em [today]; `null` quando o cartão não tem
  /// limite informado (RN-302) — sem limite não há do que tomar.
  ///
  /// [legacy] são as dívidas: entram as do tipo parcela de cartão ligadas a
  /// este cartão, que são compras de antes do app (RN-521).
  static CardLimitUsage? of(
    CreditCard card, {
    required Iterable<Entry> entries,
    required LocalDate today,
    Iterable<Reversal> reversals = const [],
    Iterable<Settlement> settlements = const [],
    Iterable<Debt> legacy = const [],
  }) {
    final limit = card.creditLimit;
    if (limit == null) return null;
    var taken = _legacyOn(card, legacy);
    for (final closing in _closingMonths(card, entries, reversals, today)) {
      final cycle = StatementCycle.closingIn(card, closing);
      final statement = CardStatement.of(
        cycle,
        entries: entries,
        reversals: reversals,
      );
      final paid = _paidOf(card, cycle.dueMonth, settlements);
      // Fatura paga a mais não devolve limite às outras: cada uma fecha em
      // zero, e a sobra é assunto do que falta lançar (RN-344).
      taken += (statement.total - paid).orZeroIfNegative;
    }
    return CardLimitUsage._(limit: limit, taken: taken);
  }

  /// O limite de crédito informado.
  final Money limit;

  /// O que está tomado: faturas em aberto e parcelas por vencer.
  final Money taken;

  /// O que ainda dá para usar. Zero quando o tomado passou do limite.
  Money get available => (limit - taken).orZeroIfNegative;

  /// Quanto o tomado passa do limite; zero no caso comum.
  Money get exceeded => (taken - limit).orZeroIfNegative;

  /// A fração tomada, para o medidor. Passa de 1 quando passou do limite;
  /// limite zero conta como todo tomado.
  double get fraction => limit.isZero ? 1 : taken.cents / limit.cents;

  static Money _paidOf(
    CreditCard card,
    BudgetMonth dueMonth,
    Iterable<Settlement> settlements,
  ) => settlements
      .where((s) => s.cardId == card.id && s.dueMonth == dueMonth)
      .fold(Money.zero, (sum, settlement) => sum + settlement.amount);

  static Money _legacyOn(CreditCard card, Iterable<Debt> debts) => debts
      .where((d) => d.kind == DebtKind.cardInstallment && d.cardId == card.id)
      .fold(Money.zero, (sum, debt) => sum + debt.outstandingBalance);

  /// Os meses de fechamento de toda fatura que pode ter algo: da primeira
  /// compra até a última parcela, o último estorno ou a fatura aberta hoje.
  static Iterable<BudgetMonth> _closingMonths(
    CreditCard card,
    Iterable<Entry> entries,
    Iterable<Reversal> reversals,
    LocalDate today,
  ) sync* {
    final dates = [
      today,
      for (final entry in entries)
        if (_isOn(card, entry)) ..._datesOf(card, entry),
      for (final reversal in reversals)
        if (reversal.line.paymentMethodId == card.id) reversal.occurredOn,
    ];
    final months = [
      for (final date in dates)
        StatementCycle.containing(card, date).closesOn.budgetMonth,
    ]..sort();
    for (var m = months.first; !m.isAfter(months.last); m = m.next) {
      yield m;
    }
  }

  static bool _isOn(CreditCard card, Entry entry) =>
      entry.paymentLines.any((line) => line.paymentMethodId == card.id);

  /// O dia da compra e, na parcelada, um dia dentro do ciclo de cada
  /// parcela: a primeira vem na fatura do ciclo da compra, e cada uma das
  /// seguintes um mês depois (RN-311).
  static Iterable<LocalDate> _datesOf(CreditCard card, Entry entry) sync* {
    yield entry.occurredOn;
    final plan = entry.installmentPlan;
    if (plan == null || plan.cardId != card.id) return;
    final first = StatementCycle.containing(card, entry.occurredOn);
    final closing = first.closesOn.budgetMonth;
    yield StatementCycle.closingIn(
      card,
      closing.addMonths(plan.count - 1),
    ).startsOn;
  }
}
