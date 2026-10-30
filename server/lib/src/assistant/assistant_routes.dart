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
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/request_body.dart';
import 'package:server/src/ledger/household_facts.dart';
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
  /// um minuto atrás já conta na resposta. Os números do mês são os que o
  /// celular mandou, quando mandou — os da tela dele, mesmo com algo ainda
  /// por sincronizar; sem eles, os que o servidor tem.
  AssistantContext _contextWith(MonthFigures? month) => AssistantContext.build(
    today: clock.today(),
    entries: state.entries,
    categories: state.categories,
    reversals: state.reversals.values,
    sheet: month == null
        ? SheetNumbers.of(ServerFinances.of(state), clock.today())
        : SheetNumbers.from(month, clock.today()),
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
    'dividas': _debts,
    'formas_de_pagamento': PaymentChoice.options,
  };

  /// As dívidas que a Juju pode abater (`abater_divida`), com o que ainda se
  /// deve hoje. Parcela no cartão fica de fora: ela se paga pela fatura.
  List<Map<String, Object?>> get _debts {
    final today = clock.today();
    return [
      for (final debt in ServerFinances.of(state).debts)
        if (debt.kind != DebtKind.cardInstallment)
          {
            'id': debt.id,
            'credor': debt.creditor,
            'ainda_deve_centavos': DebtCalendar.outstandingOn(
              debt,
              today,
            ).cents,
          },
    ];
  }

  /// O aviso que vai no cadastro quando a conversa vem da consulta pela web
  /// (RN-906). As instruções fixas não mudam — são o começo que a IA guarda
  /// em cache (RN-916) —, e sem o aviso a Juju diria que lançou o que não
  /// pôde lançar.
  static const _consultOnly =
      'esta conversa vem da consulta pela web, que só lê. Você não lança, '
      'não cancela, não registra renda e não muda categoria daqui; se a '
      'pessoa pedir, diga numa frase que isso se faz no celular.';

  /// O roteador, montado em `/v1/assistant`.
  Router get router => Router()..post('/ask', _ask);

  Future<Response> _ask(Request request) =>
      RequestBody.handle(request, _questionOf, (question) async {
        final assistant = service;
        if (assistant == null) return Responses.error(request, ErrorCode.ai01);
        final session = Authenticate.sessionOf(request);
        final readOnly = session.scope == SessionScope.webReadOnly;
        final outcome = await assistant.ask(
          sessionId: session.deviceId,
          message: question.message,
          context: _contextWith(question.month),
          catalog: {..._catalog, if (readOnly) 'acesso': _consultOnly},
          tools: _tools(readOnly: readOnly),
          householdNames: HouseholdFacts.namesIn(state),
        );
        return _reply(request, outcome);
      });

  /// A pergunta e os números do mês que a tela mostra, já conferidos.
  static ({String message, MonthFigures? month}) _questionOf(Object? raw) {
    final body = JsonReader(raw, allowed: const {'message', 'month'});
    return (
      message: body.string(
        'message',
        maxLength: AssistantPrompt.maxMessageLength,
      ),
      month: MonthFigures.fromJson(raw is Map ? raw['month'] : null),
    );
  }

  static Response _reply(Request request, AssistantOutcome outcome) {
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

  AssistantTools _tools({required bool readOnly}) => AssistantTools(
    state: state,
    store: store,
    clock: clock,
    readOnly: readOnly,
  );
}
