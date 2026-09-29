import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_failure.dart';
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
  Future<bool> canAuthenticate() async =>
      await _ask<bool>('canAuthenticate') ?? false;

  @override
  Future<Uint8List> publicKey() async =>
      await _ask<Uint8List>('publicKey') ?? Uint8List(0);

  @override
  Future<Uint8List> sign(Uint8List message) async =>
      await _ask<Uint8List>('sign', {'message': message}) ?? Uint8List(0);

  @override
  Future<Uint8List> signQuietly(Uint8List message) async =>
      await _ask<Uint8List>('signQuietly', {'message': message}) ??
      Uint8List(0);

  /// Pergunta ao lado nativo e traduz a recusa dele.
  ///
  /// O canal devolve o código do catálogo no lugar do nome da exceção, então
  /// aqui não há adivinhação: código conhecido vira ele mesmo; qualquer outra
  /// coisa vira `E-AUTH-01`, que é o "não deu para usar a chave" do catálogo.
  Future<T?> _ask<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (failure) {
      throw DeviceKeyFailure(
        ErrorCode.tryParse(failure.code) ?? ErrorCode.auth01,
      );
    } on MissingPluginException {
      // Aparelho sem o lado nativo — só acontece em build de teste.
      throw const DeviceKeyFailure(ErrorCode.auth01);
    }
  }
}
