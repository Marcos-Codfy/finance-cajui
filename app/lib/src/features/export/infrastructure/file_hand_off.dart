import 'dart:typed_data';

/// Quem entrega um arquivo pronto para fora do app: no Android, a tela de
/// compartilhar; no navegador, o download.
abstract interface class FileHandOff {
  /// Entrega [bytes] com o nome [name] e o tipo [mimeType].
  Future<void> handOff({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  });
}
