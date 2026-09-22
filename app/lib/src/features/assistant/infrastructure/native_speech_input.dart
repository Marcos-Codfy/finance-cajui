import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:flutter/services.dart';

/// O reconhecimento de fala do Android, pelo canal `app.cajui/voice`
/// (ADR-018).
final class NativeSpeechInput implements SpeechInput {
  /// Cria a porta. O canal entra por parâmetro para o teste simular o lado
  /// nativo.
  const new({this._channel = const MethodChannel('app.cajui/voice')});

  final MethodChannel _channel;

  @override
  Future<bool> isAvailable() async => await _ask<bool>('isAvailable') ?? false;

  @override
  Future<String?> listen() => _ask<String>('listen');

  /// Falha do lado nativo vira "não entendi": ditar é conveniência, e
  /// conveniência que quebra a tela deixa de ser conveniência.
  Future<T?> _ask<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
