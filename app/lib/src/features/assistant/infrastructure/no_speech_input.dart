import 'package:cajui/src/features/assistant/application/speech_input.dart';

/// Onde não há reconhecedor: a web, e o teste.
final class NoSpeechInput implements SpeechInput {
  /// Cria a porta vazia.
  const new();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<String?> listen() async => null;
}
