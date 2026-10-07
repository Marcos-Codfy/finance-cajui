import 'dart:convert';

import 'package:server/src/http/payload_too_large.dart';
import 'package:shelf/shelf.dart';

/// Lê o corpo de uma requisição como JSON, com teto de tamanho.
abstract final class JsonBody {
  /// O maior corpo aceito. Um lançamento tem centenas de bytes; o texto de um
  /// comprovante, alguns milhares. Acima disto é engano ou abuso (T-25).
  static const int maxBytes = 64 * 1024;

  /// O JSON do corpo de [request]. Lança [PayloadTooLarge] acima de
  /// [limit] — por padrão [maxBytes] — e [FormatException] quando não é JSON
  /// válido. Só a rota que recebe a foto do comprovante pede mais.
  static Future<Object?> read(Request request, {int limit = maxBytes}) async {
    final bytes = <int>[];
    await for (final chunk in request.read()) {
      bytes.addAll(chunk);
      if (bytes.length > limit) throw const PayloadTooLarge();
    }
    return jsonDecode(utf8.decode(bytes));
  }
}
