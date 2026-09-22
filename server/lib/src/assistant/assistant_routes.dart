import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/assistant/assistant_context.dart';
import 'package:server/src/assistant/assistant_prompt.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/authenticate.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A rota da conversa com o assistente.
///
/// Recebe **só a pergunta**. O contexto é montado aqui, no servidor, a partir
/// do estado dos lançamentos (RN-915): o app nunca manda número para o chat,
/// então não há como alguém forjar o contexto pelo lado de fora. E este
/// código só **lê** o estado — não tem como gravar fato financeiro (RN-904).
final class AssistantRoutes {
  /// Cria as rotas. Sem [service] — servidor sem a credencial da IA —, toda
  /// pergunta recebe `E-AI-01`, e o resto do app segue funcionando.
  new({required this.state, required this.clock, this.service});

  /// O estado dos lançamentos, só para leitura.
  final LedgerState state;

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
    plan: state.plan,
    received: state.receivedIn(clock.today().budgetMonth),
    voucherBalance: state.voucherBalance,
  );

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
    final session = Authenticate.sessionOf(request);
    final outcome = await assistant.ask(
      sessionId: '${session.deviceId}/${session.scope.name}',
      message: message,
      context: _context,
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
