import 'package:persistence/persistence.dart';
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
///
/// Desde a ADR-024 o aparelho entra com a chave da casa. A sessão daqui é a
/// da web que entrou com o código de seis dígitos do autenticador (ADR-027):
/// longa, e gravada no registro — só o hash —, para um reinício do servidor
/// não pedir o código de novo.
final class SessionBook {
  /// Cria o livro. [now] existe para o teste controlar o relógio.
  new({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Quanto dura uma sessão completa: curta, porque renovar é barato.
  static const deviceLifetime = Duration(minutes: 15);

  /// Quanto dura uma sessão só de leitura. Mais longa, porque quem só
  /// consulta não deveria ser interrompido no meio da leitura.
  static const webLifetime = Duration(hours: 2);

  /// Quanto dura a sessão aberta pelo código do autenticador: o dono pediu
  /// sessão longa, e a sessão só lê e conversa (RN-906).
  static const codeLifetime = Duration(days: 30);

  /// O tipo do evento que guarda a sessão aberta pelo código.
  static const openedType = 'auth.session-opened';

  final DateTime Function() _now;
  final Map<String, Session> _byTokenHash = {};

  /// Abre uma sessão para [deviceId] e devolve o token, em claro, uma vez.
  /// [lifetime] troca o prazo padrão do escopo.
  String open(
    String deviceId, {
    required SessionScope scope,
    Duration? lifetime,
  }) {
    final token = SecureRandom.token();
    final duration =
        lifetime ??
        (scope == SessionScope.webReadOnly ? webLifetime : deviceLifetime);
    _byTokenHash[SecureRandom.hash(token)] = Session(
      deviceId: deviceId,
      scope: scope,
      expiresAt: _now().add(duration),
    );
    return token;
  }

  /// O que gravar no registro para a sessão de [token]: o hash, nunca o
  /// token em claro.
  Map<String, Object?> recordOf(String token) {
    final hash = SecureRandom.hash(token);
    final session = _byTokenHash[hash]!;
    return {
      'hash': hash,
      'deviceId': session.deviceId,
      'scope': session.scope.name,
      'expiresAt': session.expiresAt.toUtc().toIso8601String(),
    };
  }

  /// Reabre as sessões gravadas em [events] que ainda não venceram.
  void restore(Iterable<StoredEvent> events) {
    for (final event in events) {
      if (event.type != openedType) continue;
      final payload = event.payload;
      final expiresAt = DateTime.tryParse('${payload['expiresAt']}');
      if (expiresAt == null || _now().isAfter(expiresAt)) continue;
      _byTokenHash['${payload['hash']}'] = Session(
        deviceId: '${payload['deviceId']}',
        scope:
            SessionScope.values.asNameMap()['${payload['scope']}'] ??
            SessionScope.webReadOnly,
        expiresAt: expiresAt,
      );
    }
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

  /// Encerra todas as sessões de [deviceId]: é o que sair de um aparelho
  /// precisa fazer na hora, e não só no próximo login.
  void closeAllOf(String deviceId) =>
      _byTokenHash.removeWhere((_, session) => session.deviceId == deviceId);
}
