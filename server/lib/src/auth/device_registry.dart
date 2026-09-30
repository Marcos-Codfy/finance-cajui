import 'dart:convert';

import 'package:persistence/persistence.dart';
import 'package:server/src/auth/enrolled_device.dart';
import 'package:server/src/auth/session_scope.dart';

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
  final Map<String, EnrolledDevice> _devices = {};

  /// Quantos eventos de cada tipo o aparelho já teve. É o que dá a cada
  /// cadastro e a cada revogação um identificador **próprio**: o registro é
  /// idempotente por identificador, e o mesmo aparelho voltando depois de
  /// revogado — a chave é a mesma, então o identificador também — devolvia
  /// o evento antigo sem gravar nada. Ele entrava só na memória, com o nome
  /// velho, e sumia no próximo reinício do servidor. Foi o que aconteceu
  /// com o S22 em 30/09.
  final Map<String, int> _enrollments = {};
  final Map<String, int> _revocations = {};

  void _apply(StoredEvent event) {
    final deviceId = '${event.payload['deviceId']}';
    if (event.type == enrolled) {
      _enrollments[deviceId] = (_enrollments[deviceId] ?? 0) + 1;
      _publicKeys[deviceId] = base64Decode('${event.payload['publicKey']}');
      _devices[deviceId] = EnrolledDevice(
        id: deviceId,
        name: '${event.payload['name']}',
        // Aparelho cadastrado antes de existir o campo é do app: a web só
        // passou a existir como escopo depois.
        scope: '${event.payload['kind']}' == 'web'
            ? SessionScope.webReadOnly
            : SessionScope.device,
      );
    } else if (event.type == revoked) {
      _revocations[deviceId] = (_revocations[deviceId] ?? 0) + 1;
      _publicKeys.remove(deviceId);
      _devices.remove(deviceId);
    }
  }

  /// O identificador do próximo evento de [deviceId]: o primeiro cadastro
  /// mantém a forma antiga, que já está gravada nos registros existentes.
  String _nextId(String prefix, String deviceId, Map<String, int> counts) {
    final count = counts[deviceId] ?? 0;
    return count == 0 ? '$prefix-$deviceId' : '$prefix-$deviceId-$count';
  }

  /// A chave pública de [deviceId]; nulo se ele não existe ou foi revogado.
  List<int>? publicKeyOf(String deviceId) => _publicKeys[deviceId];

  /// O que uma sessão deste aparelho pode fazer. A web lê e não escreve, e
  /// isso é decidido **no cadastro**, não na tela (T-12).
  SessionScope scopeOf(String deviceId) =>
      _devices[deviceId]?.scope ?? SessionScope.device;

  /// Os aparelhos cadastrados agora, para a pessoa ver e poder revogar.
  List<EnrolledDevice> get devices => [..._devices.values];

  /// Tira o aparelho [deviceId] do cadastro (RNF-SEC): a chave pública some,
  /// e a sessão dele morre no próximo desafio.
  Future<void> revoke(String deviceId) async {
    if (!_devices.containsKey(deviceId)) return;
    final event = await _store.append(
      id: _nextId('device-revoked', deviceId, _revocations),
      type: revoked,
      payload: {'deviceId': deviceId},
    );
    _apply(event);
  }

  /// Cadastra o aparelho, gravando o evento antes de passar a aceitá-lo.
  Future<void> enroll({
    required String deviceId,
    required String name,
    required List<int> publicKey,
    SessionScope scope = SessionScope.device,
  }) async {
    final event = await _store.append(
      id: _nextId('device', deviceId, _enrollments),
      type: enrolled,
      payload: {
        'deviceId': deviceId,
        'name': name,
        'publicKey': base64Encode(publicKey),
        'kind': scope == SessionScope.webReadOnly ? 'web' : 'device',
      },
    );
    _apply(event);
  }
}
