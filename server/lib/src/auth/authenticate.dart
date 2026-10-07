import 'package:api_contract/api_contract.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:server/src/auth/session.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/error_response.dart';
import 'package:shelf/shelf.dart';

/// Exige a chave da casa, ou uma sessão válida, em tudo o que não é rota
/// pública — e impõe o escopo.
abstract final class Authenticate {
  /// A chave em que a sessão viaja no contexto da requisição.
  static const sessionKey = 'cajui.session';

  /// O cabeçalho em que o aparelho diz quem é. Não prova nada — quem prova
  /// é a chave —; serve para cada aparelho ter a sua conversa com o
  /// assistente. Sem ele, vale um nome só para a casa inteira.
  static const deviceHeader = 'x-cajui-device';

  static const _publicPrefix = 'v1/auth/';

  /// "Estou de pé", e nada além disso: é o que o deploy e um vigia de fora
  /// perguntam antes de existir sessão nenhuma. A resposta não conta nada
  /// sobre esta casa (T-12).
  static const _healthPath = 'health';
  static const _readMethods = {'GET', 'HEAD'};

  /// A única rota que não é de leitura e é permitida à sessão da web
  /// pareada (RN-906): conversar não grava fato financeiro nenhum.
  static const _chatPath = 'v1/assistant/ask';

  static final _deviceName = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static final _never = DateTime.utc(9999);

  /// A sessão da requisição [request], posta pelo middleware.
  static Session sessionOf(Request request) =>
      request.context[sessionKey]! as Session;

  /// O middleware. Sem chave, sem token, com token desconhecido ou vencido:
  /// `E-AUTH-03`, igual em todos os casos. Sessão da web tentando escrever:
  /// `E-AUTH-03` também — o servidor não explica a quem não devia estar
  /// tentando (T-12).
  static Middleware middleware(SessionBook sessions, {HouseholdKey? key}) =>
      (inner) => (request) {
        if (request.url.path == _healthPath ||
            request.url.path.startsWith(_publicPrefix)) {
          return inner(request);
        }
        final session = _sessionOf(request, sessions, key);
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

  /// A chave da casa abre uma sessão **completa** e sem prazo: o segredo não
  /// vence, e quem o tem é o dono. O que não é a chave ainda pode ser o
  /// token de um aparelho cadastrado do jeito antigo.
  static Session? _sessionOf(
    Request request,
    SessionBook sessions,
    HouseholdKey? key,
  ) {
    final header = request.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ')) return null;
    final token = header.substring(7);
    if (key != null && key.matches(token)) {
      return Session(
        deviceId: _deviceOf(request),
        scope: SessionScope.device,
        expiresAt: _never,
      );
    }
    return sessions.find(token);
  }

  static String _deviceOf(Request request) {
    final name = request.headers[deviceHeader]?.trim() ?? '';
    return _deviceName.hasMatch(name) ? name : 'casa';
  }
}
