import 'dart:typed_data';

/// A identidade deste aparelho: a chave pública do Keystore do Android.
///
/// Já não prova nada ao servidor — quem prova é a chave da casa (ADR-020).
/// Serve para o aparelho ter um nome estável: é dele que sai o
/// identificador que separa a conversa de cada celular com o assistente, e
/// que já estava gravado nos registros antes da chave da casa existir.
abstract interface class DeviceKeyStore {
  /// Se este aparelho tem onde guardar uma chave. Na web não há.
  bool get exists;

  /// A chave pública em X.509 DER.
  Future<Uint8List> publicKey();
}
