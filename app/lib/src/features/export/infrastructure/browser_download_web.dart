import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cajui/src/features/export/infrastructure/file_hand_off.dart';
import 'package:web/web.dart' as web;

/// A entrega na web: o arquivo baixa direto, com o nome do mês — a consulta
/// pela web também leva o mês para a planilha (RN-1090).
final class BrowserDownload implements FileHandOff {
  /// Cria a entrega.
  const new();

  @override
  Future<void> handOff({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    (web.document.createElement('a') as web.HTMLAnchorElement
          ..href = url
          ..download = name)
        .click();
    web.URL.revokeObjectURL(url);
  }
}
