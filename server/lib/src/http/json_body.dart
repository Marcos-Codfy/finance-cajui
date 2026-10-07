import 'dart:convert';
import 'dart:typed_data';

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
    // O tamanho declarado já diz se passa: recusa antes de ler um byte.
    final declared = request.contentLength;
    if (declared != null && declared > limit) throw const PayloadTooLarge();
    // Um byte por byte. A lista de `int` guardava oito por byte, e três
    // fotos ao mesmo tempo levavam o processo ao teto de memória do serviço.
    final bytes = BytesBuilder();
    await for (final chunk in request.read()) {
      bytes.add(chunk);
      if (bytes.length > limit) throw const PayloadTooLarge();
    }
    return jsonDecode(utf8.decode(bytes.takeBytes()));
  }
}
