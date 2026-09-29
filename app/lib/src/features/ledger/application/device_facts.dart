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
    MonthClosed() => true,
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
    _ => null,
  };

  static DebtInstallmentPaid _payment(Map<String, Object?> payload) {
    final (:debtId, :entryId) = DebtCodec.decodePayment(payload);
    return DebtInstallmentPaid(debtId: debtId, entryId: entryId);
  }
}
