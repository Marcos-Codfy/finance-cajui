import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:server/src/assistant/assistant_actions.dart';
import 'package:server/src/assistant/assistant_tool_catalog.dart';
import 'package:server/src/assistant/entry_listing.dart';
import 'package:server/src/assistant/tool_args.dart';
import 'package:server/src/assistant/tool_outcome.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// Quem atende os pedidos de ferramenta do modelo (ADR-021).
///
/// Recebe o pedido como veio, confere cada argumento, roda a consulta ou a
/// ação e devolve o resultado em texto — nunca uma exceção: o que a
/// ferramenta recusa volta ao modelo como motivo, e ele corrige o pedido ou
/// explica à pessoa.
final class AssistantTools {
  /// Cria as ferramentas sobre o estado [state], o registro [store] e o
  /// relógio [clock].
  new({required this.state, required this.store, required this.clock})
    : _actions = AssistantActions(state: state, store: store, clock: clock);

  /// A projeção do livro.
  final LedgerState state;

  /// O registro de eventos.
  final EventStore store;

  /// De onde vem o dia de hoje.
  final Clock clock;

  final AssistantActions _actions;

  /// Atende [call].
  Future<ToolOutcome> run(ToolCall call) async {
    try {
      return await _dispatch(call);
    } on ToolRefusal catch (refusal) {
      return ToolOutcome.failed(refusal.message);
    }
  }

  Future<ToolOutcome> _dispatch(ToolCall call) => switch (call.name) {
    AssistantToolCatalog.recordExpense => _actions.record(call.arguments),
    AssistantToolCatalog.cancelEntry => _actions.cancel(call.arguments),
    AssistantToolCatalog.recordIncome => _actions.income(call.arguments),
    AssistantToolCatalog.listEntries => _list(call.arguments),
    _ => Future.value(
      ToolOutcome.failed('ferramenta desconhecida: ${call.name}'),
    ),
  };

  Future<ToolOutcome> _list(Map<String, Object?> args) async {
    final month = ToolArgs.month(args, 'mes') ?? clock.today().budgetMonth;
    return ToolOutcome.done(EntryListing.of(state, month: month));
  }
}
