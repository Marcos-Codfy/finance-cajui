import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/assistant/assistant_context.dart';
import 'package:server/src/assistant/assistant_prompt.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/assistant/assistant_tools.dart';
import 'package:server/src/assistant/payment_choice.dart';
import 'package:server/src/assistant/server_finances.dart';
import 'package:server/src/assistant/sheet_numbers.dart';
import 'package:server/src/auth/authenticate.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A rota da conversa com o assistente.
///
/// Recebe **só a pergunta**. O resumo do mês e o cadastro são montados aqui,
/// no servidor, a partir do estado (RN-915); as ferramentas que a IA pede
/// escrevem no mesmo registro das rotas, pelo mesmo caminho (ADR-021).
final class AssistantRoutes {
  /// Cria as rotas. Sem [service] — servidor sem a credencial da IA —, toda
  /// pergunta recebe `E-AI-01`, e o resto do app segue funcionando.
  new({
    required this.state,
    required this.store,
    required this.clock,
    this.service,
  });

  /// O estado dos lançamentos.
  final LedgerState state;

  /// O registro de eventos, por onde as ferramentas gravam.
  final EventStore store;

  /// De onde vem o dia de hoje.
  final Clock clock;

  /// Quem fala com a IA.
  final AssistantService? service;

  /// O contexto do mês de hoje, montado a cada pergunta: um lançamento feito
  /// um minuto atrás já conta na resposta.
  AssistantContext get _context => AssistantContext.build(
    today: clock.today(),
    entries: state.entries,
    categories: state.categories,
    reversals: state.reversals.values,
    sheet: SheetNumbers.of(ServerFinances.of(state), clock.today()),
    received: state.receivedIn(clock.today().budgetMonth),
  );

  /// O que a IA pode citar nas ferramentas: as categorias e os cartões
  /// pelos identificadores, e as formas de pagamento fixas.
  Map<String, Object?> get _catalog => {
    'categorias': [
      for (final category in state.categories.values)
        {
          'id': category.id,
          'nome': category.name,
          'bloco': category.block.name,
        },
    ],
    'cartoes': [
      for (final card in state.cards.values) {'id': card.id, 'nome': card.name},
    ],
    // Os salários da planilha, para "recebi o salário da Bia" cair no da
    // Bia (registrar_renda com salario_id).
    'salarios': [
      for (final salary in ServerFinances.of(state).plan.salaries)
        {
          'id': salary.id,
          'nome': salary.name,
          'esperado_centavos': salary.expectedAmount.cents,
          'dia': salary.expectedDay,
        },
    ],
    'formas_de_pagamento': PaymentChoice.options,
  };

  /// O roteador, montado em `/v1/assistant`.
  Router get router => Router()..post('/ask', _ask);

  Future<Response> _ask(Request request) async {
    final body = JsonReader(
      await JsonBody.read(request),
      allowed: const {'message'},
    );
    final message = body.string(
      'message',
      maxLength: AssistantPrompt.maxMessageLength,
    );
    final assistant = service;
    if (assistant == null) return Responses.error(request, ErrorCode.ai01);
    final outcome = await assistant.ask(
      sessionId: Authenticate.sessionOf(request).deviceId,
      message: message,
      context: _context,
      catalog: _catalog,
      tools: AssistantTools(state: state, store: store, clock: clock),
    );
    final (answer, error) = (outcome.answer, outcome.error);
    if (answer == null || error != null) {
      return Responses.error(
        request,
        error ?? ErrorCode.ai01,
        retryAfterSeconds: outcome.retryAfterSeconds,
      );
    }
    return Responses.json(answer.toJson());
  }
}
