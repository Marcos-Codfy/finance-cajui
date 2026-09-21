import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Valores aleatórios do gerador criptográfico do sistema, e o hash com que
/// eles são guardados.
///
/// Token de sessão e código de cadastro nunca ficam guardados em claro: o
/// servidor guarda o SHA-256 e compara hashes. Quem ler a memória ou o disco
/// não acha nada que sirva para entrar.
abstract final class SecureRandom {
  static final _random = Random.secure();

  /// Letras e números sem os pares que se confundem ao digitar: sem `0`/`O`,
  /// sem `1`/`I`/`L`.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// [length] bytes aleatórios.
  static Uint8List bytes(int length) => Uint8List.fromList([
    for (var i = 0; i < length; i++) _random.nextInt(256),
  ]);

  /// Um token opaco de 256 bits, em base64 seguro para URL.
  static String token() => base64UrlEncode(bytes(32)).replaceAll('=', '');

  /// Um código para ser digitado por uma pessoa, com [length] caracteres.
  static String code(int length) => [
    for (var i = 0; i < length; i++)
      _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
  ].join();

  /// O SHA-256 de [value], em hexadecimal.
  static String hash(String value) => SHA256Digest()
      .process(Uint8List.fromList(utf8.encode(value)))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}
