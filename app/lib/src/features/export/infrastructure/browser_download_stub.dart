import 'dart:typed_data';

import 'package:cajui/src/features/export/infrastructure/file_hand_off.dart';

/// O download onde não há navegador. Nunca é usado: no Android a raiz liga a
/// tela de compartilhar. Existe para o arquivo que escolhe a implementação
/// pela plataforma compilar nos dois mundos.
final class BrowserDownload implements FileHandOff {
  /// Cria a entrega vazia.
  const new();

  @override
  Future<void> handOff({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {}
}
