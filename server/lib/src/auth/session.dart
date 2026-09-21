import 'package:meta/meta.dart';
import 'package:server/src/auth/session_scope.dart';

/// Uma sessão aberta.
@immutable
final class Session {
  /// Cria a sessão.
  const new({
    required this.deviceId,
    required this.scope,
    required this.expiresAt,
  });

  /// O aparelho que abriu a sessão.
  final String deviceId;

  /// O que a sessão pode fazer.
  final SessionScope scope;

  /// Quando ela vence.
  final DateTime expiresAt;
}
