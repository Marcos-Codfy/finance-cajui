import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/dart.dart';
import 'package:meta/meta.dart';

/// Uma linha do registro, como ela fica no disco.
///
/// ```json
/// {"v":1,"seq":12,"prev":"9f2c…","n":"<nonce>","c":"<conteúdo cifrado>"}
/// ```
///
/// `seq` e `prev` vão **em claro**, e é de propósito: a cadeia pode ser
/// conferida por qualquer pessoa, em qualquer máquina, sem a chave — inclusive
/// numa cópia de backup. E os dois entram nos dados autenticados da cifra,
/// de modo que trocá-los quebra a abertura do registro (ADR-005).
@immutable
final class LogLine {
  /// Cria a linha.
  const new({
    required this.version,
    required this.seq,
    required this.previousHash,
    required this.nonce,
    required this.sealed,
  });

  /// Lê uma linha do disco. Lança [FormatException] se ela não for uma linha
  /// inteira e bem formada — o que acontece com a última linha quando o
  /// processo morre no meio de uma escrita.
  factory parse(String text) {
    final json = jsonDecode(text);
    if (json is! Map<String, Object?>) throw const FormatException('linha');
    return LogLine(
      version: json['v']! as int,
      seq: json['seq']! as int,
      previousHash: json['prev']! as String,
      nonce: base64Decode(json['n']! as String),
      sealed: base64Decode(json['c']! as String),
    );
  }

  /// O `prev` da primeira linha do registro: não há linha anterior.
  static const genesis = '';

  /// A versão da cifra que produziu a linha.
  final int version;

  /// A posição no registro, a partir de 1.
  final int seq;

  /// O SHA-256 da linha anterior, em hexadecimal.
  final String previousHash;

  /// O nonce usado para cifrar este registro.
  final Uint8List nonce;

  /// O evento cifrado, com a marca de autenticação.
  final Uint8List sealed;

  /// Os dados autenticados junto com o conteúdo: mudar a versão, a posição
  /// ou o elo com a linha anterior invalida o registro.
  static List<int> associatedData(int version, int seq, String previousHash) =>
      utf8.encode('$version|$seq|$previousHash');

  /// O SHA-256 de [line], em hexadecimal: o elo que a linha seguinte guarda.
  static String hashOf(String line) {
    final digest = const DartSha256().hashSync(utf8.encode(line));
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// A linha como vai para o disco, sem a quebra de linha.
  String encode() => jsonEncode({
    'v': version,
    'seq': seq,
    'prev': previousHash,
    'n': base64Encode(nonce),
    'c': base64Encode(sealed),
  });
}
