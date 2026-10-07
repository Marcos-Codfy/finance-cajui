import 'dart:convert';

/// A imagem de um comprovante, como ela atravessa o servidor até a IA
/// (ADR-022): o tipo, conferido pelos primeiros bytes, e o endereço de dados
/// com que o provedor a recebe.
///
/// O tipo nunca vem do que o app declarou: imagem que não começa como JPEG,
/// PNG ou WebP é recusada antes de sair daqui.
abstract final class ReceiptImage {
  /// O tipo de [bytes], ou `null` quando não é uma imagem que a IA lê.
  static String? mimeOf(List<int> bytes) {
    if (_starts(bytes, const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (_starts(bytes, const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 'RIFF') &&
        _ascii(bytes, 8, 'WEBP')) {
      return 'image/webp';
    }
    return null;
  }

  /// [bytes] como endereço de dados, no formato que o provedor aceita.
  static String dataUrl(List<int> bytes) =>
      'data:${mimeOf(bytes) ?? 'image/jpeg'};base64,${base64Encode(bytes)}';

  static bool _starts(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  static bool _ascii(List<int> bytes, int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      if (bytes[offset + i] != text.codeUnitAt(i)) return false;
    }
    return true;
  }
}
