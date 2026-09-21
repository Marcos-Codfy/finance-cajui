import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Confere a assinatura que o aparelho faz do desafio do servidor: ECDSA
/// sobre a curva P-256, com SHA-256 — o que o Android Keystore produz com
/// `SHA256withECDSA` (ADR-008).
///
/// É a peça que faz a biometria valer como fator: o servidor não acredita
/// num "a biometria passou"; acredita numa assinatura que só a chave presa
/// no hardware do aparelho consegue produzir (T-02).
abstract final class SignatureVerifier {
  /// O cabeçalho fixo de uma chave pública P-256 no formato X.509
  /// (`SubjectPublicKeyInfo`). Depois dele vêm os 65 bytes do ponto.
  static final _spkiHeader = Uint8List.fromList([
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, //
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00,
  ]);

  static final _curve = ECCurve_secp256r1();

  /// [publicKey] é uma chave P-256 bem formada, em X.509.
  static bool isValidPublicKey(List<int> publicKey) {
    if (publicKey.length != _spkiHeader.length + 65) return false;
    for (var i = 0; i < _spkiHeader.length; i++) {
      if (publicKey[i] != _spkiHeader[i]) return false;
    }
    return publicKey[_spkiHeader.length] == 0x04;
  }

  /// A [signature] (em DER) de [message] foi feita pela dona de [publicKey].
  /// Qualquer coisa malformada é só "não confere": nunca uma exceção que
  /// diga ao atacante o que errou.
  static bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
  }) {
    if (!isValidPublicKey(publicKey)) return false;
    try {
      final point = _curve.curve.decodePoint(
        publicKey.sublist(_spkiHeader.length),
      );
      final parsed = ASN1Parser(Uint8List.fromList(signature)).nextObject();
      final parts = (parsed as ASN1Sequence).elements!;
      final verifier = Signer('SHA-256/ECDSA')
        ..init(false, PublicKeyParameter(ECPublicKey(point, _curve)));
      return verifier.verifySignature(
        Uint8List.fromList(message),
        ECSignature(
          (parts[0] as ASN1Integer).integer!,
          (parts[1] as ASN1Integer).integer!,
        ),
      );
    } on Object {
      return false;
    }
  }
}
