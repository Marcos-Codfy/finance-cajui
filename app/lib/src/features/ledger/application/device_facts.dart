import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';

/// A ida e a volta entre os fatos que **só o aparelho interpreta** e o
/// formato em que eles viajam: fatura paga, dívida, parcela de dívida paga
/// e mês fechado (ADR-019).
///
/// O servidor os guarda e devolve sem fazer conta com eles. É o que faz o
/// outro celular — e o celular reinstalado — mostrar as mesmas dívidas e os
/// mesmos fechamentos, sem ninguém digitar de novo.
abstract final class DeviceFacts {
  /// Se [event] é um dos fatos que viajam assim.
  static bool covers(LedgerEvent event) => switch (event) {
    StatementSettled() ||
    DebtDefined() ||
    DebtInstallmentPaid() ||
    MonthClosed() ||
    BudgetDefined() ||
    DebtOrdered() ||
    HouseholdNamed() ||
    IncomeCancelled() ||
    AnswerLearned() => true,
    _ => false,
  };

  /// O fato [event] como viaja; `null` quando não é um dos quatro.
  static DeviceFact? of(LedgerEvent event) => switch (event) {
    StatementSettled(:final settlement) => DeviceFact(
      id: event.id,
      type: DeviceFact.statementSettled,
      payload: CardCodec.encodeSettlement(settlement),
    ),
    DebtDefined(:final debt) => DeviceFact(
      id: event.id,
      type: DeviceFact.debtDefined,
      payload: DebtCodec.encodeDebt(debt),
    ),
    DebtInstallmentPaid(:final debtId, :final entryId) => DeviceFact(
      id: event.id,
      type: DeviceFact.debtInstallmentPaid,
      payload: DebtCodec.encodePayment((debtId: debtId, entryId: entryId)),
    ),
    MonthClosed(:final close) => DeviceFact(
      id: event.id,
      type: DeviceFact.monthClosed,
      payload: MonthCloseCodec.encode(close),
    ),
    BudgetDefined() || DebtOrdered() || HouseholdNamed() => _budget(event),
    IncomeCancelled() || AnswerLearned() => _statement(event),
    _ => null,
  };

  /// O recebimento desfeito (RN-1120) e a resposta lembrada (RN-1116).
  static DeviceFact? _statement(LedgerEvent event) => switch (event) {
    IncomeCancelled(:final receiptId, :final on) => DeviceFact(
      id: event.id,
      type: DeviceFact.incomeCancelled,
      payload: IncomeCancellationCodec.encode((receiptId: receiptId, on: on)),
    ),
    AnswerLearned(:final answer) => DeviceFact(
      id: event.id,
      type: DeviceFact.merchantLearned,
      payload: LearnedAnswerCodec.encode(answer),
    ),
    _ => null,
  };

  /// O plano da planilha, a ordem das dívidas (ADR-023) e os nomes da casa
  /// (RN-1070).
  static DeviceFact? _budget(LedgerEvent event) => switch (event) {
    HouseholdNamed(:final names) => DeviceFact(
      id: event.id,
      type: DeviceFact.householdNamed,
      payload: HouseholdCodec.encode(names),
    ),
    BudgetDefined(:final plan) => DeviceFact(
      id: event.id,
      type: DeviceFact.budgetDefined,
      payload: BudgetPlanCodec.encode(plan),
    ),
    DebtOrdered(:final ids, :final definedAt) => DeviceFact(
      id: event.id,
      type: DeviceFact.debtOrdered,
      payload: DebtCodec.encodeOrdering((ids: ids, definedAt: definedAt)),
    ),
    _ => null,
  };

  /// O fato [fact], vindo do servidor, como fato do livro; `null` para um
  /// tipo que esta versão do app não conhece.
  static LedgerEvent? toEvent(DeviceFact fact) => switch (fact.type) {
    DeviceFact.statementSettled => StatementSettled(
      CardCodec.decodeSettlement(fact.payload),
    ),
    DeviceFact.debtDefined => DebtDefined(
      id: fact.id,
      debt: DebtCodec.decodeDebt(fact.payload),
    ),
    DeviceFact.debtInstallmentPaid => _payment(fact.payload),
    DeviceFact.monthClosed => MonthClosed(MonthCloseCodec.decode(fact.payload)),
    DeviceFact.budgetDefined => BudgetDefined(
      BudgetPlanCodec.decode(fact.payload),
    ),
    DeviceFact.debtOrdered => _ordering(fact.payload),
    DeviceFact.householdNamed => HouseholdNamed(
      HouseholdCodec.decode(fact.payload),
    ),
    _ => _statementEvent(fact),
  };

  /// O recebimento desfeito e a resposta lembrada, vindos do servidor. A
  /// resposta guarda o identificador do fato: é ele que diz ao servidor
  /// que ela já está lá.
  static LedgerEvent? _statementEvent(DeviceFact fact) {
    switch (fact.type) {
      case DeviceFact.incomeCancelled:
        final (:receiptId, :on) = IncomeCancellationCodec.decode(fact.payload);
        return IncomeCancelled(receiptId: receiptId, on: on);
      case DeviceFact.merchantLearned:
        return AnswerLearned(
          id: fact.id,
          answer: LearnedAnswerCodec.decode(fact.payload),
        );
    }
    return null;
  }

  static DebtOrdered _ordering(Map<String, Object?> payload) {
    final (:ids, :definedAt) = DebtCodec.decodeOrdering(payload);
    return DebtOrdered(ids: ids, definedAt: definedAt);
  }

  static DebtInstallmentPaid _payment(Map<String, Object?> payload) {
    final (:debtId, :entryId) = DebtCodec.decodePayment(payload);
    return DebtInstallmentPaid(debtId: debtId, entryId: entryId);
  }
}
