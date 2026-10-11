import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pointycastle/export.dart' hide SecureRandom;
import 'package:server/src/auth/secure_random.dart';

/// O código de seis dígitos do autenticador (RFC 6238, ADR-027): o mesmo
/// que o Google Authenticator mostra, e que o script do PC também calcula.
///
/// O segredo nasce no PC do dono e chega aqui cifrado, como a chave da
/// casa. Vale o passo de 30 segundos de agora e os dois vizinhos — relógio
/// de celular adianta ou atrasa —, e cada passo vale **uma vez**: o código
/// visto por cima do ombro não abre uma segunda sessão.
final class Totp {
  /// Cria o verificador com o segredo, em bytes.
  new(this._secret);

  /// O nome da credencial que o systemd entrega ao serviço.
  static const credentialName = 'cajui-totp';

  /// Segredo mais curto que isto (80 bits, o mínimo da RFC 4226) é erro de
  /// configuração, e não segredo.
  static const minBytes = 10;

  static const _stepSeconds = 30;
  static const _digits = 6;
  static final _sixDigits = RegExp(r'^\d{6}$');
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  final Uint8List _secret;
  int? _lastStep;

  /// Uma impressão curta do segredo, que vai junto de cada sessão gravada:
  /// a sessão aberta por um segredo que já foi trocado não volta depois de
  /// um reinício. É um hash de 160 bits aleatórios — não ajuda a achá-lo.
  late final String fingerprint = SecureRandom.hash(base64Encode(_secret))
      .substring(0, 16);

  /// O verificador lido da credencial do systemd, ou do arquivo [file] —
  /// para rodar fora de um serviço. `null` sem segredo: aí ninguém entra
  /// por código, e a chave da casa continua valendo.
  static Totp? load({required Map<String, String> environment, String? file}) {
    final directory = environment['CREDENTIALS_DIRECTORY'];
    final path =
        file ?? (directory == null ? null : p.join(directory, credentialName));
    if (path == null || !File(path).existsSync()) return null;
    final secret = base32(_read(path));
    return secret == null || secret.length < minBytes ? null : Totp(secret);
  }

  /// O texto do arquivo, ou vazio quando ele não se lê como UTF-8 — um BOM
  /// mal tirado, por exemplo. Segredo ilegível é só "sem segredo": o
  /// servidor sobe, e a web entra pela chave da casa.
  static String _read(String path) {
    try {
      return File(path).readAsStringSync();
    } on FileSystemException {
      return '';
    }
  }

  /// Se [code] vale em [now]. O que já foi aceito não vale de novo.
  bool accepts(String code, DateTime now) {
    if (!_sixDigits.hasMatch(code)) return false;
    final current = now.millisecondsSinceEpoch ~/ 1000 ~/ _stepSeconds;
    for (final step in [current - 1, current, current + 1]) {
      final last = _lastStep;
      if (last != null && step <= last) continue;
      if (codeAt(step) != code) continue;
      _lastStep = step;
      return true;
    }
    return false;
  }

  /// O código do passo [step] (RFC 4226: HMAC-SHA1 e truncamento dinâmico).
  String codeAt(int step) {
    final counter = ByteData(8)..setInt64(0, step);
    final mac = HMac(SHA1Digest(), 64)..init(KeyParameter(_secret));
    final hash = mac.process(counter.buffer.asUint8List());
    final offset = hash.last & 0x0f;
    final value =
        ((hash[offset] & 0x7f) << 24) |
        (hash[offset + 1] << 16) |
        (hash[offset + 2] << 8) |
        hash[offset + 3];
    return (value % 1000000).toString().padLeft(_digits, '0');
  }

  /// Os bytes de [text] em base32 (RFC 4648), o formato que o autenticador
  /// aceita; espaços e minúsculas são tolerados. `null` quando não é base32.
  static Uint8List? base32(String text) {
    final clean = text.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    final bytes = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final char in clean.split('')) {
      final value = _alphabet.indexOf(char);
      if (value < 0) return null;
      // Só os últimos bits importam: guardar mais estouraria o inteiro.
      buffer = ((buffer << 5) | value) & 0xffff;
      bits += 5;
      if (bits < 8) continue;
      bits -= 8;
      bytes.add((buffer >> bits) & 0xff);
    }
    return Uint8List.fromList(bytes);
  }
}
