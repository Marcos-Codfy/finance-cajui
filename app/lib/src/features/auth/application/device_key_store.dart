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

  /// Se dá para confirmar quem é aqui: digital, rosto ou desbloqueio. Sem
  /// isso a chave não assina, e o aparelho não conversa com o servidor.
  Future<bool> canAuthenticate();

  /// A chave pública em X.509 DER, como o servidor a espera.
  Future<Uint8List> publicKey();

  /// A assinatura de [message] em DER, feita pela chave privada **depois de
  /// o Android confirmar quem está ali**.
  ///
  /// Vazia quando a pessoa fechou a caixa de diálogo: desistir não é erro, e
  /// quem chamou trata como "não agora".
  Future<Uint8List> sign(Uint8List message);

  /// A assinatura de [message] **sem perguntar nada a ninguém**: só sai se
  /// a liberação do dia ainda vale. Vazia quando a janela fechou — e aí
  /// quem chamou espera o próximo envio pedido, em vez de interromper.
  Future<Uint8List> signQuietly(Uint8List message);
}

/// A chave deste aparelho. A raiz do app decide qual.
final deviceKeyStoreProvider = Provider<DeviceKeyStore>(
  (ref) => throw StateError('deviceKeyStoreProvider sem override na raiz.'),
);
