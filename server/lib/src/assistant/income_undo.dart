import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/assistant/tool_outcome.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// Desfaz um recebimento a pedido da pessoa (RN-1120), pelo mesmo
/// `cancelar_lancamento` que cancela uma despesa.
///
/// Até 17/11/2026 uma entrada de dinheiro registrada errada só saía pelo
/// "Desfazer tudo" da leitura de extrato: a Juju a via, contava na renda do
/// mês e não tinha como tirá-la. Nada é apagado: o fato `income.cancelled`
/// fica no registro ao lado do recebimento, e desce aos celulares como o
/// desfazer de qualquer aparelho.
final class IncomeUndo {
  /// Cria sobre o estado [state], o registro [store] e o relógio.
  const new({required this.state, required this.store, required this.clock});

  /// A projeção do livro.
  final LedgerState state;

  /// O registro de eventos.
  final EventStore store;

  /// De onde vem o dia de hoje.
  final Clock clock;

  /// Se [id] é de um recebimento em vigor.
  bool owns(String id) => state.receipts.containsKey(id);

  /// Desfaz o recebimento [id], que [owns] já confirmou.
  Future<ToolOutcome> cancel(String id) async {
    final receipt = state.receipts[id]!;
    final cancellation = (receiptId: id, on: clock.today());
    final event = await store.append(
      id: 'income-cancelled-$id',
      type: DeviceFact.incomeCancelled,
      payload: {
        'id': 'income-cancelled-$id',
        'payload': IncomeCancellationCodec.encode(cancellation),
      },
    );
    state.apply(event);
    return ToolOutcome.done({
      'ok': true,
      'id': id,
      'recebimento_desfeito_centavos': receipt.amount.cents,
    });
  }
}
