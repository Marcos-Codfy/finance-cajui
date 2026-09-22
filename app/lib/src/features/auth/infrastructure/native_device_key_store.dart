import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:flutter/services.dart';

/// A chave do aparelho guardada no Keystore do Android, pelo canal
/// `app.cajui/device` (ADR-008).
final class NativeDeviceKeyStore implements DeviceKeyStore {
  /// Cria a porta. O canal entra por parâmetro para o teste simular o lado
  /// nativo.
  const new({this._channel = const MethodChannel('app.cajui/device')});

  final MethodChannel _channel;

  @override
  bool get exists => true;

  @override
  Future<Uint8List> publicKey() async =>
      await _channel.invokeMethod<Uint8List>('publicKey') ?? Uint8List(0);

  @override
  Future<Uint8List> sign(Uint8List message) async =>
      await _channel.invokeMethod<Uint8List>('sign', {'message': message}) ??
      Uint8List(0);
}
