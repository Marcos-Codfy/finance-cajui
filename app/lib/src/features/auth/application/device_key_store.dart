import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A identidade deste aparelho perante o servidor (ADR-008).
///
/// É uma porta porque a chave privada **não existe no Dart**: no Android ela
/// mora no Keystore, e o que atravessa esta interface é só o pedido de
/// assinatura. Na web não há identidade de aparelho nenhuma — lá a sessão
/// nasce de um pareamento com o celular.
abstract interface class DeviceKeyStore {
  /// Se este aparelho tem onde guardar uma chave.
  bool get exists;

  /// A chave pública em X.509 DER, como o servidor a espera.
  Future<Uint8List> publicKey();

  /// A assinatura de [message] em DER, feita pela chave privada.
  Future<Uint8List> sign(Uint8List message);
}

/// A chave deste aparelho. A raiz do app decide qual.
final deviceKeyStoreProvider = Provider<DeviceKeyStore>(
  (ref) => throw StateError('deviceKeyStoreProvider sem override na raiz.'),
);
