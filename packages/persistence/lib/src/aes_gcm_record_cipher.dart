import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:persistence/src/record_cipher.dart';
import 'package:persistence/src/record_tampered_exception.dart';

/// AES-256-GCM: cifra **autenticada**, com nonce de 96 bits novo a cada
/// registro (ADR-005).
///
/// A implementação é a do pacote `cryptography`, em Dart puro, para não levar
/// biblioteca nativa à compilação cruzada do servidor. Não há biblioteca
/// criptográfica validada formalmente em Dart: é a exceção 11.2.1 do
/// checklist do ASVS, compensada por algoritmo padrão conferido contra vetor
/// de teste publicado e por este formato versionado.
final class AesGcmRecordCipher implements RecordCipher {
  /// Cria a cifra com a chave de dados [keyBytes], de 32 bytes.
  new(List<int> keyBytes)
    : assert(keyBytes.length == 32, 'A chave de dados tem 32 bytes.'),
      _key = SecretKey(List.unmodifiable(keyBytes));

  static final _algorithm = AesGcm.with256bits();
  static const _macLength = 16;

  final SecretKey _key;

  @override
  int get version => 1;

  @override
  Future<({Uint8List nonce, Uint8List sealed})> seal(
    List<int> plaintext, {
    required List<int> associated,
  }) async {
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: _key,
      aad: associated,
    );
    final sealed = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
    return (nonce: Uint8List.fromList(box.nonce), sealed: sealed);
  }

  @override
  Future<Uint8List> open({
    required List<int> nonce,
    required List<int> sealed,
    required List<int> associated,
  }) async {
    if (sealed.length < _macLength) throw const RecordTamperedException();
    final split = sealed.length - _macLength;
    final box = SecretBox(
      sealed.sublist(0, split),
      nonce: nonce,
      mac: Mac(sealed.sublist(split)),
    );
    try {
      final opened = await _algorithm.decrypt(
        box,
        secretKey: _key,
        aad: associated,
      );
      return Uint8List.fromList(opened);
    } on SecretBoxAuthenticationError {
      throw const RecordTamperedException();
    }
  }
}
