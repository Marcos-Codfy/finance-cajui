import 'package:server/src/auth/secure_random.dart';
import 'package:server/src/auth/session.dart';
import 'package:server/src/auth/session_scope.dart';

/// As sessões abertas. Os tokens são **opacos**: valores aleatórios que só
/// significam algo neste livro.
///
/// Com um servidor só, isso é mais simples e mais seguro que um token
/// autocontido: revogar é apagar, e não há assinatura para validar nem lista
/// de bloqueio para manter (ADR-008). O livro guarda o hash do token, nunca o
/// token.
final class SessionBook {
  /// Cria o livro. [now] existe para o teste controlar o relógio.
  new({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Quanto dura a sessão do app: curta, e renovada pela biometria.
  static const deviceLifetime = Duration(minutes: 15);

  /// Quanto dura a sessão da web. Mais longa que a do app porque o navegador
  /// **não tem como se renovar sozinho** — não há chave ali para assinar um
  /// desafio novo. Vencida, pede-se outro código ao celular. Ela morre com a
  /// aba de qualquer jeito: nada é guardado no navegador (ADR-013).
  static const webLifetime = Duration(hours: 2);

  final DateTime Function() _now;
  final Map<String, Session> _byTokenHash = {};

  /// Abre uma sessão para [deviceId] e devolve o token, em claro, uma vez.
  String open(String deviceId, {required SessionScope scope}) {
    final token = SecureRandom.token();
    final lifetime = scope == SessionScope.webReadOnly
        ? webLifetime
        : deviceLifetime;
    _byTokenHash[SecureRandom.hash(token)] = Session(
      deviceId: deviceId,
      scope: scope,
      expiresAt: _now().add(lifetime),
    );
    return token;
  }

  /// A sessão do [token], se ele existe e não venceu.
  Session? find(String token) {
    final key = SecureRandom.hash(token);
    final session = _byTokenHash[key];
    if (session == null) return null;
    if (_now().isAfter(session.expiresAt)) {
      _byTokenHash.remove(key);
      return null;
    }
    return session;
  }

  /// Encerra todas as sessões de [deviceId]: é o que acontece quando o
  /// aparelho é revogado.
  void closeAllOf(String deviceId) =>
      _byTokenHash.removeWhere((_, session) => session.deviceId == deviceId);
}
