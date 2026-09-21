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
import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/http/middlewares.dart';
import 'package:server/src/http/rate_limiter.dart';
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
  new({
    required EventStore store,
    required Directory dataDirectory,
    required Clock clock,
    required this._log,
    required this.sessions,
    RateLimiter? rateLimiter,
    this.classifier = const RuleBasedClassifier(),
    this.assistant,
  }) : _clock = clock,
       _limiter = rateLimiter ?? RateLimiter(perOrigin: 120, global: 600),
       _auth = AuthRoutes(
         devices: DeviceRegistry(store),
         codes: EnrollmentCodes(dataDirectory),
         challenges: ChallengeBook(),
         sessions: sessions,
       ),
       _ledger = LedgerRoutes(
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
  final LedgerRoutes _ledger;

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

  /// O tratador de requisições, pronto para o `shelf_io`.
  ///
  /// A ordem importa: o identificador nasce primeiro, para todo o resto poder
  /// citá-lo; o registro de acesso vê a resposta final, inclusive a de erro;
  /// o limite de taxa vem **antes** da autenticação, para que tentar senha
  /// errada também gaste cota.
  Handler get handler {
    final routes = Router()
      ..mount('/v1/auth', _auth.router.call)
      ..mount('/v1/receipts', _receipts.router.call)
      ..mount('/v1/assistant', _assistant.router.call)
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
