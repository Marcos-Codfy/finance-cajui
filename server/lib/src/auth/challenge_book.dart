import 'dart:typed_data';

import 'package:server/src/auth/secure_random.dart';

/// Os desafios em aberto: o número aleatório que o aparelho precisa assinar
/// para entrar.
///
/// Cada desafio vale 2 minutos e **uma vez só** — é o que impede que uma
/// assinatura capturada seja reapresentada depois (T-04).
final class ChallengeBook {
  /// Cria o livro. [now] existe para o teste controlar o relógio.
  new({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Por quanto tempo um desafio vale.
  static const validity = Duration(minutes: 2);

  final DateTime Function() _now;
  final Map<String, ({String deviceId, Uint8List nonce, DateTime expires})>
  _open = {};

  /// Emite um desafio para [deviceId] — exista o aparelho ou não. Responder
  /// igual nos dois casos é o que impede descobrir, por fora, quais aparelhos
  /// estão cadastrados (RNF-SEC-18).
  ({String id, Uint8List nonce}) issue(String deviceId) {
    _open.removeWhere((_, challenge) => _now().isAfter(challenge.expires));
    final id = SecureRandom.token();
    final nonce = SecureRandom.bytes(32);
    _open[id] = (
      deviceId: deviceId,
      nonce: nonce,
      expires: _now().add(validity),
    );
    return (id: id, nonce: nonce);
  }

  /// Retira o desafio [id] do livro. Devolve nulo se ele não existe, já foi
  /// usado ou venceu.
  ({String deviceId, Uint8List nonce})? take(String id) {
    final challenge = _open.remove(id);
    if (challenge == null || _now().isAfter(challenge.expires)) return null;
    return (deviceId: challenge.deviceId, nonce: challenge.nonce);
  }
}
