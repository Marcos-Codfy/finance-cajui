import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Um par de chaves P-256, como o que o Android Keystore guardaria, para o
/// teste fazer o papel do aparelho.
final class TestDevice {
  /// Gera um aparelho de teste com chave nova.
  factory generate() {
    final curve = ECCurve_secp256r1();
    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(ECKeyGeneratorParameters(curve), _random(1)));
    final pair = generator.generateKeyPair();
    const header = [
      0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, //
      0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07,
      0x03, 0x42, 0x00,
    ];
    return TestDevice._(
      pair.privateKey,
      Uint8List.fromList([...header, ...pair.publicKey.Q!.getEncoded(false)]),
    );
  }

  new _(this._private, this.publicKeyX509);

  final ECPrivateKey _private;

  /// A chave pública no formato X.509, como o app a envia no cadastro.
  final Uint8List publicKeyX509;

  static FortunaRandom _random(int seed) =>
      FortunaRandom()
        ..seed(KeyParameter(Uint8List.fromList(List.filled(32, seed))));

  /// Assina [message] com SHA-256/ECDSA e devolve a assinatura em DER, como
  /// faz o `SHA256withECDSA` do Android.
  Uint8List sign(List<int> message) {
    final signer = Signer('SHA-256/ECDSA')
      ..init(
        true,
        ParametersWithRandom(
          PrivateKeyParameter<ECPrivateKey>(_private),
          _random(9),
        ),
      );
    final signature =
        signer.generateSignature(Uint8List.fromList(message)) as ECSignature;
    final sequence = ASN1Sequence()
      ..add(ASN1Integer(signature.r))
      ..add(ASN1Integer(signature.s));
    return sequence.encode();
  }
}
