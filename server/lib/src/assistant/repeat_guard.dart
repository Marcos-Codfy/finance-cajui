import 'package:api_contract/api_contract.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// O freio contra o lançamento em dobro pela conversa.
///
/// O defeito de antes era este: a pessoa pedia, a resposta não chegava (ou
/// chegava dizendo que não deu), ela pedia de novo, e o mesmo gasto entrava
/// duas vezes. Agora, um lançamento com o mesmo valor, no mesmo dia e pela
/// mesma forma de pagamento de um que já existe volta ao modelo como
/// pergunta: ele confere com a pessoa e, se for outro gasto de verdade —
/// dois cafés iguais existem —, pede de novo com `repetido`.
abstract final class RepeatGuard {
  /// Recusa [request] se ele repete um lançamento vivo de [state], a menos
  /// que [confirmed] diga que a pessoa confirmou que é outro.
  static void check(
    CreateEntryRequest request,
    LedgerState state, {
    required bool confirmed,
  }) {
    if (confirmed) return;
    final method = request.paymentLines.first.paymentMethodId;
    for (final entry in state.entries) {
      final same =
          entry.amount.cents == request.amountCents &&
          '${entry.occurredOn}' == request.occurredOn &&
          entry.paymentLines.first.paymentMethodId == method;
      if (same) {
        throw ToolRefusal(
          'já existe um lançamento igual neste dia (id ${entry.id}, '
          '"${entry.description}"); nada foi gravado. Pergunte à pessoa se é '
          'outro gasto. Se for, chame lancar_despesa de novo com '
          'repetido=true; se não, diga que já estava lançado',
        );
      }
    }
  }
}
