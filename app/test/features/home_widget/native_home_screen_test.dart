import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:cajui/src/features/home_widget/infrastructure/native_home_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('app.cajui/home-test');

void _answer(Future<Object?> Function(MethodCall call) handler) =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, handler);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const screen = NativeHomeScreen(channel: _channel);

  test('ADR-025 · o lado nativo diz onde está o widget', () async {
    for (final placement in ['placed', 'absent', 'manual']) {
      _answer((call) async => placement);

      expect((await screen.placement()).name, placement);
    }
  });

  test('resposta estranha ou falha do lado nativo: a linha some', () async {
    _answer((call) async => 'outro');
    expect(await screen.placement(), WidgetPlacement.unavailable);

    _answer((call) async => throw PlatformException(code: 'E-APP-01'));
    expect(await screen.placement(), WidgetPlacement.unavailable);
  });

  test('pôr na tela é o pedido "pin" ao lado nativo', () async {
    final calls = <String>[];
    _answer((call) async {
      calls.add(call.method);
      return true;
    });

    await screen.pin();

    expect(calls, ['pin']);
  });
}
