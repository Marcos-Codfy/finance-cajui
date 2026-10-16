import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:server/src/assistant/assistant_actions.dart';
import 'package:server/src/assistant/assistant_tool_catalog.dart';
import 'package:server/src/assistant/debt_paydown.dart';
import 'package:server/src/assistant/due_bills_listing.dart';
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
  /// relógio [clock]. Com [readOnly] — a sessão da web que entrou com o
  /// código —, só a consulta.
  new({
    required this.state,
    required this.store,
    required this.clock,
    this.readOnly = false,
  }) : _actions = AssistantActions(state: state, store: store, clock: clock);

  late final DebtPaydown _paydown = DebtPaydown(
    state: state,
    store: store,
    clock: clock,
    actions: _actions,
  );

  /// A projeção do livro.
  final LedgerState state;

  /// O registro de eventos.
  final EventStore store;

  /// De onde vem o dia de hoje.
  final Clock clock;

  /// Se a sessão só lê (RN-906). A conversa passa, as ferramentas que gravam
  /// não: sem isso, a sessão de trinta dias do código lançaria e cancelaria
  /// pela Juju o que a rota de lançamentos recusa.
  final bool readOnly;

  final AssistantActions _actions;

  /// As ferramentas que vão para o modelo: na sessão só de leitura, só a
  /// consulta — o que não é oferecido o modelo nem tenta.
  List<ChatTool> get offered => readOnly
      ? [
          for (final tool in AssistantToolCatalog.tools)
            if (AssistantToolCatalog.readOnly.contains(tool.name)) tool,
        ]
      : AssistantToolCatalog.tools;

  /// Atende [call]. Na sessão só de leitura, o que grava é recusado aqui
  /// também, para o caso de o modelo pedir o que não lhe foi oferecido.
  Future<ToolOutcome> run(ToolCall call) async {
    if (readOnly && !AssistantToolCatalog.readOnly.contains(call.name)) {
      return ToolOutcome.failed(readOnlyRefusal);
    }
    try {
      return await _dispatch(call);
    } on ToolRefusal catch (refusal) {
      return ToolOutcome.failed(refusal.message);
    }
  }

  /// O motivo, nas palavras que o modelo lê, de não gravar nada na consulta.
  static const readOnlyRefusal =
      'esta conversa vem da consulta pela web, que só lê: lançar, cancelar, '
      'registrar renda, mudar categoria e abater dívida se fazem no celular';

  Future<ToolOutcome> _dispatch(ToolCall call) => switch (call.name) {
    AssistantToolCatalog.recordExpense => _actions.record(call.arguments),
    AssistantToolCatalog.cancelEntry => _actions.cancel(call.arguments),
    AssistantToolCatalog.recordIncome => _actions.income(call.arguments),
    AssistantToolCatalog.recategorize => _actions.recategorize(call.arguments),
    AssistantToolCatalog.payDownDebt => _paydown.pay(call.arguments),
    AssistantToolCatalog.listEntries => _list(call.arguments),
    AssistantToolCatalog.dueBills => Future.value(
      ToolOutcome.done({'contas': DueBillsListing.of(state, clock.today())}),
    ),
    _ => Future.value(
      ToolOutcome.failed('ferramenta desconhecida: ${call.name}'),
    ),
  };

  Future<ToolOutcome> _list(Map<String, Object?> args) async {
    final month = ToolArgs.month(args, 'mes') ?? clock.today().budgetMonth;
    return ToolOutcome.done(EntryListing.of(state, month: month));
  }
}
