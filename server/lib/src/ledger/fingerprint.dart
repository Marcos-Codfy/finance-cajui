import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// A impressão digital de um conteúdo, para a chave de idempotência de um
/// fato que pode mudar: correção de lançamento, plano, cartão, categoria.
///
/// A chave nasce do próprio conteúdo: reenviar a mesma coisa não cria fato
/// novo, e uma versão diferente cria — sem o app ter de contar versões.
abstract final class Fingerprint {
  /// Oito caracteres do SHA-256 de [payload]: o bastante para separar duas
  /// versões e curto o bastante para caber num identificador legível.
  static String of(Map<String, Object?> payload) {
    final bytes = utf8.encode(jsonEncode(payload));
    final digest = SHA256Digest().process(Uint8List.fromList(bytes));
    return digest
        .take(4)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
