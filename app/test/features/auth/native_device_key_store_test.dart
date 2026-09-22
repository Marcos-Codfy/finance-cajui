import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_failure.dart';
import 'package:cajui/src/features/auth/infrastructure/native_device_key_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.cajui/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void refuseWith(String code) => messenger.setMockMethodCallHandler(
    channel,
    (call) async => throw PlatformException(code: code),
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('a recusa do Keystore atravessa o canal como falha tipada', () {
    test('E-AUTH-01 · o Keystore não deixou usar a chave', () {
      refuseWith('E-AUTH-01');

      expect(
        const NativeDeviceKeyStore().sign(Uint8List(4)),
        throwsA(
          isA<DeviceKeyFailure>().having(
            (failure) => failure.code,
            'código',
            ErrorCode.auth01,
          ),
        ),
      );
    });

    test('E-AUTH-03 · digital trocada invalida a chave', () {
      refuseWith('E-AUTH-03');

      expect(
        const NativeDeviceKeyStore().publicKey(),
        throwsA(
          isA<DeviceKeyFailure>().having(
            (failure) => failure.code,
            'código',
            ErrorCode.auth03,
          ),
        ),
      );
    });

    test('código que o catálogo não conhece não vira exceção solta', () {
      refuseWith('QUALQUER_COISA');

      expect(
        const NativeDeviceKeyStore().canAuthenticate(),
        throwsA(isA<DeviceKeyFailure>()),
      );
    });
  });
}
