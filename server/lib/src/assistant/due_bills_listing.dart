import 'package:domain/domain.dart';
import 'package:server/src/assistant/server_finances.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// As contas do mês ainda não pagas, pela ferramenta `contas_a_pagar` da
/// Juju (16/10/2026): é o que responde "o que falta pagar?", e o
/// `categoria_id` de cada uma é o que o `lancar_despesa` usa para pagá-la. A conta é a mesma dos lembretes
/// de vencimento (`DueBills`): o mês inteiro, inclusive o que já venceu, e
/// sem o que se paga no cartão — esse vai na fatura.
abstract final class DueBillsListing {
  /// As contas abertas do mês de [today] em [state].
  static List<Map<String, Object?>> of(LedgerState state, LocalDate today) {
    final month = today.budgetMonth;
    final finances = ServerFinances.of(state);
    final window = DueWindow.from(month.firstDay, days: month.length - 1);
    final lines = {
      for (final line in finances.planFor(month).lines) line.id: line,
    };
    return [
      for (final bill in DueBills.within(
        window,
        finances,
        cardIds: state.cards.keys.toSet(),
      ))
        {
          'conta': bill.name,
          'categoria_id': lines[bill.id]?.categoryId,
          'valor_centavos': bill.amount.cents,
          'vence': '${bill.dueOn}',
          if (bill.dueOn.isBefore(today)) 'vencida': true,
        },
    ];
  }
}
