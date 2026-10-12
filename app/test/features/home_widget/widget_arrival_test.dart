import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/home_widget/presentation/widget_arrival.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';
import '../notifications/fake_notice_device.dart';

Future<(FakeNoticeDevice, ProviderContainer)> _open(
  WidgetTester tester, {
  String? route,
}) async {
  tester.view.physicalSize = const Size(400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final device = FakeNoticeDevice()..pendingRoute = route;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
        bankNoticeDeviceProvider.overrideWithValue(device),
        launchRequestsProvider.overrideWithValue(device),
        notificationAccessProvider.overrideWithValue(device),
      ],
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CajuiApp)),
  );
  return (device, container);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('o número do widget, tocado com o app fechado, abre o Início '
      'com a chegada pelo vidro', (tester) async {
    final (_, container) = await _open(tester, route: WidgetArrival.route);

    expect(container.read(homeTabProvider), HomeTab.inicio);
    expect(container.read(widgetArrivalProvider), 1);
    final arrival = tester.widget<CajuiGlassArrival>(
      find.byType(CajuiGlassArrival),
    );
    expect(arrival.arrival, 1);
  });

  testWidgets('com o app aberto noutra tela, o número do widget fecha o que '
      'estiver por cima e leva ao Início', (tester) async {
    final (device, container) = await _open(tester);
    expect(container.read(homeTabProvider), HomeTab.conversar);

    device.request('reminder:bills');
    await _settle(tester);
    expect(find.byType(MyBillsPage), findsOneWidget);

    device.request(WidgetArrival.route);
    await _settle(tester);

    expect(find.byType(MyBillsPage), findsNothing);
    expect(container.read(homeTabProvider), HomeTab.inicio);
    expect(container.read(widgetArrivalProvider), 1);
  });
}
