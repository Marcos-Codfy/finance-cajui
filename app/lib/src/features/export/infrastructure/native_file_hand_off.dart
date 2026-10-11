import 'package:cajui/src/features/export/infrastructure/file_hand_off.dart';
import 'package:flutter/services.dart';

/// A entrega pelo Android: o arquivo vai para a pasta temporária do app e
/// sai pela tela de compartilhar — salvar em Arquivos, mandar no WhatsApp,
/// abrir no Excel ou no Planilhas. O lado nativo está em
/// `FileShareChannel.kt`.
final class NativeFileHandOff implements FileHandOff {
  /// Cria a entrega.
  const new();

  static const _channel = MethodChannel('cajui/files');

  @override
  Future<void> handOff({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) => _channel.invokeMethod<void>('share', {
    'name': name,
    'mimeType': mimeType,
    'bytes': bytes,
  });
}
