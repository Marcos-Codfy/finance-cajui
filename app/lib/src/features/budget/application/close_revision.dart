import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

/// A revisão que um lançamento tardio exige de um mês já fechado (RN-441).
///
/// O fechamento é retrato imutável (RN-440): quando um fato muda o resultado
/// de um mês fechado, não se reescreve o fechamento — grava-se uma revisão
/// nova. A anterior continua no registro, e a diferença entre as duas é o
/// que a tela mostra.
abstract final class CloseRevision {
  /// As revisões que [event] exige, aplicado sobre [before] e resultando em
  /// [after]. Vazio quando nenhum mês fechado mudou de resultado.
  ///
  /// Uma correção pode mudar a data do lançamento e mexer em **dois** meses
  /// fechados: o de onde ele saiu e o para onde foi.
  static List<MonthClosed> after({
    required LedgerBook before,
    required LedgerBook after,
    required LedgerEvent event,
    required LocalDate today,
  }) => [
    for (final month in _monthsTouchedBy(event, before))
      ?_revisionFor(after, month, today),
  ];

  static MonthClosed? _revisionFor(
    LedgerBook book,
    BudgetMonth month,
    LocalDate today,
  ) {
    final close = book.closeOf(month);
    if (close == null) return null;
    final result = book.cashResultIn(month);
    if (result == close.cashResult) return null;
    return MonthClosed(close.revisedWith(cashResult: result, on: today));
  }

  /// Os meses cujo **resultado realizado** [event] pode ter mudado (RN-623).
  ///
  /// Plano, cartão, fatura paga e ajuste de saldo do vale ficam de fora: não
  /// entram na renda recebida nem na despesa em dinheiro do mês.
  static Set<BudgetMonth> _monthsTouchedBy(
    LedgerEvent event,
    LedgerBook before,
  ) => switch (event) {
    EntryRecorded(:final entry) => {entry.occurredOn.budgetMonth},
    EntryCorrected(:final entry) => {
      entry.occurredOn.budgetMonth,
      ?before.entryOf(entry.id)?.occurredOn.budgetMonth,
    },
    EntryCancelled(:final entryId) => {
      ?before.entryOf(entryId)?.occurredOn.budgetMonth,
    },
    EntryReversed(:final reversal) => {reversal.occurredOn.budgetMonth},
    IncomeReceived(:final receipt) => {receipt.receivedOn.budgetMonth},
    _ => const {},
  };
}
