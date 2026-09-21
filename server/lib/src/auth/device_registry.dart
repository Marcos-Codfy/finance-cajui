import 'dart:convert';

import 'package:persistence/persistence.dart';

/// Os aparelhos cadastrados e a chave pública de cada um, reconstruídos a
/// partir dos eventos.
///
/// O servidor guarda só chaves **públicas**: nada aqui serve para entrar. A
/// chave privada nunca saiu do hardware do aparelho.
final class DeviceRegistry {
  /// Reconstrói o cadastro aplicando os eventos do registro, na ordem.
  new(this._store) {
    _store.events.forEach(_apply);
  }

  /// O tipo do evento de cadastro.
  static const enrolled = 'device.enrolled';

  /// O tipo do evento de revogação.
  static const revoked = 'device.revoked';

  final EventStore _store;
  final Map<String, List<int>> _publicKeys = {};

  void _apply(StoredEvent event) {
    final deviceId = '${event.payload['deviceId']}';
    if (event.type == enrolled) {
      _publicKeys[deviceId] = base64Decode('${event.payload['publicKey']}');
    } else if (event.type == revoked) {
      _publicKeys.remove(deviceId);
    }
  }

  /// A chave pública de [deviceId]; nulo se ele não existe ou foi revogado.
  List<int>? publicKeyOf(String deviceId) => _publicKeys[deviceId];

  /// Cadastra o aparelho, gravando o evento antes de passar a aceitá-lo.
  Future<void> enroll({
    required String deviceId,
    required String name,
    required List<int> publicKey,
  }) async {
    final event = await _store.append(
      id: 'device-$deviceId',
      type: enrolled,
      payload: {
        'deviceId': deviceId,
        'name': name,
        'publicKey': base64Encode(publicKey),
      },
    );
    _apply(event);
  }
}
