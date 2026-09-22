import 'dart:io';

import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/receipt_routes.dart';
import 'package:server/src/assistant/assistant_routes.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/auth_routes.dart';
import 'package:server/src/auth/authenticate.dart';
import 'package:server/src/auth/challenge_book.dart';
import 'package:server/src/auth/device_registry.dart';
import 'package:server/src/auth/device_routes.dart';
import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/web_codes.dart';
import 'package:server/src/http/middlewares.dart';
import 'package:server/src/http/rate_limiter.dart';
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
  /// O cadastro de aparelhos e os códigos de convite são **os mesmos** para
  /// as rotas públicas de autenticação e para as de dentro: um convite
  /// emitido pelo celular é o que o cadastro do computador consome.
  new({
    required EventStore store,
    required Directory dataDirectory,
    required Clock clock,
    required void Function(String line) log,
    required SessionBook sessions,
    RateLimiter? rateLimiter,
    ReceiptClassifier classifier = const RuleBasedClassifier(),
    AssistantService? assistant,
  }) : this._shared(
         store: store,
         devices: DeviceRegistry(store),
         codes: EnrollmentCodes(dataDirectory),
         clock: clock,
         log: log,
         sessions: sessions,
         rateLimiter: rateLimiter,
         classifier: classifier,
         assistant: assistant,
         webCodes: WebCodes(),
       );

  new _shared({
    required EventStore store,
    required DeviceRegistry devices,
    required EnrollmentCodes codes,
    required Clock clock,
    required this._log,
    required this.sessions,
    required RateLimiter? rateLimiter,
    required this.classifier,
    required this.assistant,
    required WebCodes webCodes,
  }) : _clock = clock,
       _limiter = rateLimiter ?? RateLimiter(perOrigin: 120, global: 600),
       _auth = AuthRoutes(
         devices: devices,
         codes: codes,
         challenges: ChallengeBook(),
         sessions: sessions,
         webCodes: webCodes,
       ),
       _devices = DeviceRoutes(
         devices: devices,
         codes: codes,
         sessions: sessions,
         webCodes: webCodes,
       ),
       _ledger = _ledgerRoutes(store, clock);

  static LedgerRoutes _ledgerRoutes(EventStore store, Clock clock) =>
      LedgerRoutes(
        store: store,
        state: LedgerState(store.events),
        clock: clock,
      );

  /// As sessões abertas. Expostas para o teste abrir uma sem passar pela
  /// biometria.
  final SessionBook sessions;

  /// Quem classifica comprovantes. Sem chave da IA, são só as regras locais —
  /// e o servidor funciona inteiro assim.
  final ReceiptClassifier classifier;

  /// Quem atende a conversa com o assistente; `null` num servidor sem a
  /// credencial da IA, que responde `E-AI-01` às perguntas.
  final AssistantService? assistant;

  final Clock _clock;
  final void Function(String line) _log;
  final RateLimiter _limiter;
  final AuthRoutes _auth;
  final DeviceRoutes _devices;
  final LedgerRoutes _ledger;

  late final IncomeRoutes _income = IncomeRoutes(
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
  /// o limite de taxa vem **antes** da autenticação, para que tentar senha
  /// errada também gaste cota.
  Handler get handler {
    final routes = Router()
      ..get('/health', _health)
      ..mount('/v1/auth', _auth.router.call)
      ..mount('/v1/devices', _devices.router.call)
      ..mount('/v1/receipts', _receipts.router.call)
      ..mount('/v1/assistant', _assistant.router.call)
      ..mount('/v1', _income.router.call)
      ..mount('/v1', _ledger.router.call);
    return const Pipeline()
        .addMiddleware(Middlewares.requestRef())
        .addMiddleware(Middlewares.accessLog(_log))
        .addMiddleware(Middlewares.errorBoundary(_log))
        .addMiddleware(Middlewares.rateLimit(_limiter))
        .addMiddleware(Authenticate.middleware(sessions))
        .addHandler(routes.call);
  }
}
