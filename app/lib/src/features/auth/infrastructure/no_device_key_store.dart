import 'dart:typed_data';

import 'package:cajui/src/features/auth/application/device_key_store.dart';

/// Onde não há Keystore: a web, que é modo consulta e não tem identidade de
/// aparelho própria (ADR-013).
///
/// Não devolve chave nem assina. Guardar chave privada no navegador seria
/// deixá-la ao alcance de qualquer extensão — lá a sessão vem do pareamento
/// com o celular.
final class NoDeviceKeyStore implements DeviceKeyStore {
  /// Cria a porta vazia.
  const new();

  @override
  bool get exists => false;

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<Uint8List> publicKey() async => Uint8List(0);

  @override
  Future<Uint8List> sign(Uint8List message) async => Uint8List(0);

  @override
  Future<Uint8List> signQuietly(Uint8List message) async => Uint8List(0);
}
