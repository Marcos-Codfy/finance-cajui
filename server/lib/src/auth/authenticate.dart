import 'package:api_contract/api_contract.dart';
import 'package:server/src/auth/session.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/error_response.dart';
import 'package:shelf/shelf.dart';

/// Exige sessão válida em tudo o que não é rota de autenticação, e impõe o
/// escopo dela.
abstract final class Authenticate {
  /// A chave em que a sessão viaja no contexto da requisição.
  static const sessionKey = 'cajui.session';

  static const _publicPrefix = 'v1/auth/';

  /// "Estou de pé", e nada além disso: é o que o deploy e um vigia de fora
  /// perguntam antes de existir sessão nenhuma. A resposta não conta nada
  /// sobre esta casa (T-12).
  static const _healthPath = 'health';
  static const _readMethods = {'GET', 'HEAD'};

  /// A única rota que não é de leitura e é permitida à sessão da web
  /// (RN-906): conversar não grava fato financeiro nenhum. O código que a
  /// atende não tem porta de escrita no registro (RN-904).
  static const _chatPath = 'v1/assistant/ask';

  /// A sessão da requisição [request], posta pelo middleware.
  static Session sessionOf(Request request) =>
      request.context[sessionKey]! as Session;

  /// O middleware. Sem token, com token desconhecido ou vencido: `E-AUTH-03`,
  /// igual nos três casos. Sessão da web tentando escrever: `E-AUTH-03`
  /// também — o servidor não explica a quem não devia estar tentando (T-12).
  static Middleware middleware(SessionBook sessions) =>
      (inner) => (request) {
        if (request.url.path == _healthPath ||
            request.url.path.startsWith(_publicPrefix)) {
          return inner(request);
        }
        final header = request.headers['authorization'] ?? '';
        final session = header.startsWith('Bearer ')
            ? sessions.find(header.substring(7))
            : null;
        if (session == null) {
          return Responses.error(request, ErrorCode.auth03, status: 401);
        }
        final writing =
            !_readMethods.contains(request.method) &&
            request.url.path != _chatPath;
        if (writing && session.scope == SessionScope.webReadOnly) {
          return Responses.error(request, ErrorCode.auth03, status: 403);
        }
        return inner(request.change(context: {sessionKey: session}));
      };
}
