import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';
import '../notifications/fake_notice_device.dart';

Future<FakeNoticeDevice> _open(WidgetTester tester, {String? route}) async {
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
  return device;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 700));
}

Finder _screen(String title) =>
    find.descendant(of: find.byType(CajuiScreen), matching: find.text(title));

void main() {
  testWidgets('RN-849 RN-1087 · o lembrete da parcela, tocado com o app '
      'fechado, abre Minhas dívidas', (tester) async {
    await _open(tester, route: 'reminder:debts');

    expect(_screen('Minhas dívidas'), findsOneWidget);
  });

  testWidgets('RN-849 RN-1087 · com o app aberto, o lembrete da conta abre '
      'Minhas contas e o da fatura abre os cartões', (tester) async {
    final device = await _open(tester);

    device.request('reminder:bills');
    await _settle(tester);
    expect(_screen('Minhas contas'), findsOneWidget);

    device.request('reminder:cards');
    await _settle(tester);
    expect(_screen('Cartões de crédito'), findsOneWidget);
  });

  testWidgets('pedido que não é de lembrete nem da revisão não abre '
      'nada', (tester) async {
    await _open(tester, route: 'reminder:outra');

    expect(_screen('Minhas dívidas'), findsNothing);
    expect(_screen('Minhas contas'), findsNothing);
  });
}
