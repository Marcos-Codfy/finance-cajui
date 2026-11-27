import 'package:cajui/src/core/device/storage_settings.dart';
import 'package:flutter/services.dart';

/// A tela de armazenamento do Android, pelo canal `app.cajui/settings`.
final class NativeStorageSettings implements StorageSettings {
  /// Cria a porta. O canal entra por parâmetro para o teste simular o lado
  /// nativo.
  const new({this._channel = const MethodChannel('app.cajui/settings')});

  final MethodChannel _channel;

  /// Aparelho sem essa tela não pode derrubar o app: o "Tentar de novo"
  /// continua ao lado.
  @override
  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('openStorage');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
