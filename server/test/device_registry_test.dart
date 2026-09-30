import 'package:server/src/auth/device_registry.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

/// O cadastro de aparelhos reconstruído do registro — como num reinício do
/// servidor. O S22 mostrou o defeito em 30/09: revogado em 22/09 e
/// cadastrado de novo com a mesma chave, ele entrava só na memória.
void main() {
  late TestApp server;
  const key = [1, 2, 3, 4];

  setUp(() async {
    server = await TestApp.start();
  });

  /// O que um servidor recém-ligado saberia do mesmo registro.
  DeviceRegistry restarted() => DeviceRegistry(server.store);

  test('ADR-008 · o aparelho que volta depois de revogado fica cadastrado '
      'também depois do reinício, com o nome novo', () async {
    final devices = DeviceRegistry(server.store);
    await devices.enroll(deviceId: 's22', name: 'Celular', publicKey: key);
    await devices.revoke('s22');

    await devices.enroll(deviceId: 's22', name: 'S22', publicKey: key);

    expect(devices.publicKeyOf('s22'), key);
    expect(devices.devices.single.name, 'S22');
    final after = restarted();
    expect(after.publicKeyOf('s22'), key, reason: 'gravado, não só lembrado');
    expect(after.devices.single.name, 'S22');
  });

  test('ADR-008 · revogar de novo, depois de voltar, vale também depois do '
      'reinício', () async {
    final devices = DeviceRegistry(server.store);
    await devices.enroll(deviceId: 's22', name: 'Celular', publicKey: key);
    await devices.revoke('s22');
    await devices.enroll(deviceId: 's22', name: 'S22', publicKey: key);

    await devices.revoke('s22');

    expect(devices.publicKeyOf('s22'), isNull);
    expect(restarted().publicKeyOf('s22'), isNull);
    expect(restarted().devices, isEmpty);
  });

  test(
    'cadastrar de novo sem revogar troca o nome, e a chave continua',
    () async {
      final devices = DeviceRegistry(server.store);
      await devices.enroll(deviceId: 's22', name: 'Celular', publicKey: key);

      await devices.enroll(deviceId: 's22', name: 'S22', publicKey: key);

      expect(restarted().devices.single.name, 'S22');
      expect(restarted().publicKeyOf('s22'), key);
    },
  );

  test('o primeiro cadastro mantém o identificador de sempre', () async {
    await DeviceRegistry(server.store)
        .enroll(deviceId: 's22', name: 'Celular', publicKey: key);

    expect(server.store.events.last.id, 'device-s22');
  });
}
