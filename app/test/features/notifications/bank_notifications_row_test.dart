import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';
import 'fake_notice_device.dart';

const _title = 'Lançar pelas notificações do banco';

Future<void> _openSettings(
  WidgetTester tester, {
  FakeNoticeDevice? device,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(),
        if (device != null) ...[
          bankNoticeDeviceProvider.overrideWithValue(device),
          notificationAccessProvider.overrideWithValue(device),
          launchRequestsProvider.overrideWithValue(device),
        ],
      ],
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Ajustes'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('RN-786 · a linha diz o que faz e que está desligado; o toque '
      'leva à tela do sistema', (tester) async {
    final device = FakeNoticeDevice();
    await _openSettings(tester, device: device);

    expect(find.text(_title), findsOneWidget);
    expect(find.textContaining('lança sozinho'), findsOneWidget);
    expect(find.text('Desligado'), findsOneWidget);

    await tester.tap(find.text(_title));
    await tester.pump();

    expect(device.settingsOpened, 1);
  });

  testWidgets('na volta da tela do sistema, a linha confere de novo e diz '
      'que ligou', (tester) async {
    final device = FakeNoticeDevice();
    await _openSettings(tester, device: device);

    device.granted = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ligado'), findsOneWidget);
  });

  testWidgets('onde não há leitor de notificações — a web —, a linha não '
      'aparece', (tester) async {
    await _openSettings(tester);

    expect(find.text(_title), findsNothing);
  });
}
