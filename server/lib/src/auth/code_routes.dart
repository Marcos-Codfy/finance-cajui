import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/auth/secure_random.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/auth/totp.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/request_body.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A entrada da web com o código de seis dígitos do autenticador (ADR-027):
/// troca o código por uma sessão longa, que só lê e conversa (RN-906).
///
/// É a única rota que responde sem chave, e por isso a única com trava:
/// cinco códigos errados seguidos fecham a porta por quinze minutos. Sem
/// ela, um código de seis dígitos se acertaria por tentativa em horas.
final class CodeRoutes {
  /// Cria as rotas sobre o verificador [totp] — `null` sem segredo —, o
  /// livro de sessões, o registro e o relógio.
  new({
    required this.totp,
    required this.sessions,
    required this.store,
    required this.clock,
  });

  /// O verificador do código; `null` num servidor sem o segredo.
  final Totp? totp;

  /// Onde a sessão nova é aberta.
  final SessionBook sessions;

  /// Onde a sessão fica gravada, para sobreviver a um reinício.
  final EventStore store;

  /// De onde vem a hora.
  final Clock clock;

  /// Quantos códigos errados seguidos fecham a porta.
  static const maxFailures = 5;

  /// Por quanto tempo a porta fica fechada.
  static const lockout = Duration(minutes: 15);

  int _failures = 0;
  DateTime? _lockedUntil;

  /// O roteador, montado em `/v1/auth`.
  Router get router => Router()..post('/code', _code);

  Future<Response> _code(Request request) =>
      RequestBody.handle(request, _codeOf, (code) async {
        // Daqui até contar o erro não há `await`: com um isolate só, conferir
        // a porta, testar o código e contar a falha acontecem juntos. Com a
        // porta conferida antes de ler o corpo, cem pedidos simultâneos
        // passavam todos por ela e furavam a trava.
        final now = clock.now();
        final verifier = totp;
        if (verifier == null || _locked(now)) return _refused(request);
        if (!verifier.accepts(code, now)) {
          _fail(now);
          return _refused(request);
        }
        _failures = 0;
        return await _opened(verifier);
      });

  /// O código de seis dígitos que veio no corpo.
  static String _codeOf(Object? json) =>
      JsonReader(json, allowed: const {'code'}).string('code', maxLength: 8);

  /// Abre a sessão longa e a grava com a impressão do segredo que a abriu:
  /// trocar o segredo derruba todas no próximo reinício (ADR-027).
  Future<Response> _opened(Totp verifier) async {
    final token = sessions.open(
      'web',
      scope: SessionScope.webReadOnly,
      lifetime: SessionBook.codeLifetime,
    );
    await store.append(
      id: 'auth-session-${SecureRandom.hash(token).substring(0, 16)}',
      type: SessionBook.openedType,
      payload: {
        ...sessions.recordOf(token),
        SessionBook.secretField: verifier.fingerprint,
      },
    );
    return Responses.json({'token': token});
  }

  bool _locked(DateTime now) {
    final until = _lockedUntil;
    return until != null && now.isBefore(until);
  }

  void _fail(DateTime now) {
    _failures++;
    if (_failures < maxFailures) return;
    _failures = 0;
    _lockedUntil = now.add(lockout);
  }

  /// A mesma resposta para código errado, porta fechada e servidor sem
  /// segredo: quem tenta não aprende nada com ela (T-12).
  static Response _refused(Request request) =>
      Responses.error(request, ErrorCode.auth03, status: 401);
}
