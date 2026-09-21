import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:meta/meta.dart';

/// Um ciclo de fatura: o intervalo de compras que caem na mesma fatura.
///
/// O dia de fechamento é o **primeiro dia do ciclo novo** (RN-303): compra
/// feita até a véspera entra na fatura que fecha; no dia do fechamento ou
/// depois, entra na seguinte.
@immutable
final class StatementCycle {
  /// O ciclo do cartão [card] que fecha no mês [closingMonth].
  factory closingIn(CreditCard card, BudgetMonth closingMonth) {
    final closesOn = closingMonth.dayClamped(card.closingDay);
    // Vencimento que, no calendário, cai antes do fechamento pertence ao mês
    // seguinte (RN-304): fecha dia 25, vence dia 5 do mês que vem.
    final dueMonth = card.dueDay > card.closingDay
        ? closingMonth
        : closingMonth.next;
    return StatementCycle._(
      cardId: card.id,
      startsOn: closingMonth.previous.dayClamped(card.closingDay),
      closesOn: closesOn,
      dueOn: dueMonth.dayClamped(card.dueDay),
    );
  }

  /// O ciclo do cartão [card] em que cai uma compra feita em [purchasedOn].
  factory containing(CreditCard card, LocalDate purchasedOn) {
    final month = purchasedOn.budgetMonth;
    final closesThisMonth = month.dayClamped(card.closingDay);
    return StatementCycle.closingIn(
      card,
      purchasedOn.isBefore(closesThisMonth) ? month : month.next,
    );
  }

  const new _({
    required this.cardId,
    required this.startsOn,
    required this.closesOn,
    required this.dueOn,
  });

  /// O cartão a que o ciclo pertence.
  final String cardId;

  /// O primeiro dia do ciclo: o fechamento da fatura anterior.
  final LocalDate startsOn;

  /// O dia em que a fatura fecha. Já **não** faz parte deste ciclo.
  final LocalDate closesOn;

  /// O dia em que a fatura vence.
  final LocalDate dueOn;

  /// O mês em que a fatura vence — é o que dá nome a ela: "fatura de
  /// outubro".
  BudgetMonth get dueMonth => dueOn.budgetMonth;

  /// Uma compra feita em [day] entra nesta fatura.
  bool contains(LocalDate day) =>
      !day.isBefore(startsOn) && day.isBefore(closesOn);

  @override
  bool operator ==(Object other) =>
      other is StatementCycle &&
      other.cardId == cardId &&
      other.closesOn == closesOn;

  @override
  int get hashCode => Object.hash(cardId, closesOn);
}
