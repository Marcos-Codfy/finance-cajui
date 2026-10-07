import 'dart:convert';

import 'package:cryptography/dart.dart';

/// O identificador deste aparelho para o servidor.
///
/// É **derivado da chave pública** do Keystore, e não sorteado: a chave já
/// é uma identidade, então não há um segundo dado a guardar nem a perder —
/// e é o mesmo identificador que os dois celulares do dono já tinham antes
/// da chave da casa (ADR-020).
abstract final class DeviceIdentity {
  /// O identificador que nasce de [publicKey].
  static String of(List<int> publicKey) {
    final digest = const DartSha256().hashSync(publicKey);
    return base64Url.encode(digest.bytes).substring(0, 32);
  }
}
