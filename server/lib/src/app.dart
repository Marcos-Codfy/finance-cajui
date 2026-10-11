import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/receipt_routes.dart';
import 'package:server/src/assistant/assistant_routes.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/authenticate.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/http/cors.dart';
import 'package:server/src/http/middlewares.dart';
import 'package:server/src/http/rate_limiter.dart';
import 'package:server/src/ledger/fact_routes.dart';
import 'package:server/src/ledger/income_routes.dart';
import 'package:server/src/ledger/ledger_routes.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A composição do servidor: que middlewares, em que ordem, sobre que rotas.
///
/// É explícita de propósito (ADR-003): lendo este arquivo se sabe tudo o que
/// acontece com uma requisição antes de ela chegar a uma rota.
final class App {
  /// Monta o servidor sobre o registro [store], já aberto.
  ///
  /// Quem entra é quem tem a chave da casa (ADR-020, ADR-024). O cadastro
  /// de aparelho com código, o desafio assinado e o código da web saíram:
  /// protegiam contra um risco que esta casa não tem e cobravam uma
  /// cerimônia a cada aparelho. O livro de sessões fica — vazio hoje — para
  /// o login com código de seis dígitos que ainda vai entrar.
  new({
    required EventStore store,
    required Clock clock,
    required this._log,
    required this.sessions,
    RateLimiter? rateLimiter,
    this.classifier = const RuleBasedClassifier(),
    this.assistant,
    this.householdKey,
    this.webOrigin = defaultWebOrigin,
  }) : _clock = clock,
       _limiter = rateLimiter ?? RateLimiter(perOrigin: 120, global: 600),
       _ledger = LedgerRoutes(
         store: store,
         state: LedgerState(store.events),
         clock: clock,
       );

  /// As sessões abertas. Sem rota que as abra por enquanto: o teste abre
  /// uma direto, para conferir que o escopo continua imposto no servidor.
  final SessionBook sessions;

  /// Quem classifica comprovantes. Sem chave da IA, são só as regras locais —
  /// e o servidor funciona inteiro assim.
  final ReceiptClassifier classifier;

  /// Quem atende a conversa com o assistente; `null` num servidor sem a
  /// credencial da IA, que responde `E-AI-01` às perguntas.
  final AssistantService? assistant;

  /// A chave da casa (ADR-020). `null` num servidor sem a credencial: aí
  /// ninguém entra, e o servidor só responde se está de pé.
  final HouseholdKey? householdKey;

  /// A única origem de navegador que pode ler as respostas: a web de
  /// consulta. Vem da composição para o teste e um ambiente de ensaio
  /// poderem apontar para outra.
  final String webOrigin;

  /// Onde a web de consulta mora (ADR-011, desvio 2 do plano).
  static const defaultWebOrigin = 'https://cajui-teal.vercel.app';

  final Clock _clock;
  final void Function(String line) _log;
  final RateLimiter _limiter;
  final LedgerRoutes _ledger;

  late final IncomeRoutes _income = IncomeRoutes(
    store: _ledger.store,
    state: _ledger.state,
  );

  late final FactRoutes _facts = FactRoutes(
    store: _ledger.store,
    state: _ledger.state,
  );

  late final ReceiptRoutes _receipts = ReceiptRoutes(
    classifier: classifier,
    state: _ledger.state,
    clock: _clock,
  );

  late final AssistantRoutes _assistant = AssistantRoutes(
    state: _ledger.state,
    store: _ledger.store,
    clock: _clock,
    service: assistant,
  );

  /// "Estou de pé" — e nada além disso.
  ///
  /// É o que o deploy pergunta depois de subir o serviço e o que um vigia
  /// perguntaria de fora. **Não diz versão, nem se a IA está ligada, nem
  /// quantos lançamentos existem**: quem não está autenticado não aprende
  /// nada sobre esta casa além de que ela responde.
  Response _health(Request request) => Response.ok(
    '{"status":"ok"}',
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  /// O tratador de requisições, pronto para o `shelf_io`.
  ///
  /// A ordem importa: o identificador nasce primeiro, para todo o resto poder
  /// citá-lo; o registro de acesso vê a resposta final, inclusive a de erro;
  /// a origem cruzada vem logo depois, **antes** de toda recusa — limite
  /// de taxa, pedido malformado, falha interna —, porque cada uma delas
  /// precisa chegar legível à web, com o código do catálogo; o limite de
  /// taxa vem antes da autenticação, para que tentar senha errada também
  /// gaste cota.
  Handler get handler {
    final routes = Router()
      ..get('/health', _health)
      ..mount('/v1/receipts', _receipts.router.call)
      ..mount('/v1/assistant', _assistant.router.call)
      ..mount('/v1', _income.router.call)
      ..mount('/v1', _facts.router.call)
      ..mount('/v1', _ledger.router.call);
    return const Pipeline()
        .addMiddleware(Middlewares.requestRef())
        .addMiddleware(Middlewares.accessLog(_log))
        .addMiddleware(Cors.allow(webOrigin))
        .addMiddleware(Middlewares.errorBoundary(_log))
        .addMiddleware(Middlewares.rateLimit(_limiter))
        .addMiddleware(Authenticate.middleware(sessions, key: householdKey))
        .addHandler(routes.call);
  }
}
