import 'dart:typed_data';

import 'package:cajui/src/features/auth/application/device_key_store.dart';

/// Onde não há Keystore: a web. O navegador não tem identidade de aparelho
/// própria; para o servidor ele é "web", e a chave da casa é quem o
/// apresenta (ADR-020).
final class NoDeviceKeyStore implements DeviceKeyStore {
  /// Cria a porta vazia.
  const new();

  @override
  bool get exists => false;

  @override
  Future<Uint8List> publicKey() async => Uint8List(0);
}
