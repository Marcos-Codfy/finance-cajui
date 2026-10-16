import 'dart:io';

import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/home_widget/presentation/new_entry_shortcut.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';
import '../notifications/fake_notice_device.dart';

/// Abre o app como o Android o abre: [route] é o pedido que a atividade
/// guardou antes de o Dart subir.
Future<(FakeNoticeDevice, MemoryLedgerJournal)> _open(
  WidgetTester tester, {
  String? route,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final device = FakeNoticeDevice()..pendingRoute = route;
  final journal = MemoryLedgerJournal();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(journal: journal),
        bankNoticeDeviceProvider.overrideWithValue(device),
        launchRequestsProvider.overrideWithValue(device),
        notificationAccessProvider.overrideWithValue(device),
      ],
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  return (device, journal);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 700));
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('o "+" do widget, tocado com o app fechado, abre o app direto '
      'no novo lançamento', (tester) async {
    await _open(tester, route: NewEntryShortcut.route);

    expect(find.byType(EntryFormPage), findsOneWidget);
    expect(find.text('Nova despesa'), findsOneWidget);
  });

  testWidgets('com o app aberto, o "+" abre o formulário por cima, e o que '
      'se lança nele fica gravado', (tester) async {
    final (device, journal) = await _open(tester);
    expect(find.byType(EntryFormPage), findsNothing);

    device.request(NewEntryShortcut.route);
    await _settle(tester);
    await tester.enterText(_field('Valor'), '850');
    await tester.enterText(_field('O que foi'), 'Ônibus');
    await tester.tap(find.text('Lançar'));
    await _settle(tester);

    expect(find.byType(EntryFormPage), findsNothing);
    expect(await journal.readAll(), hasLength(1));
  });

  testWidgets('pedido que não é o do "+" não abre formulário nenhum', (
    tester,
  ) async {
    final (device, _) = await _open(tester, route: 'new-entry-x');
    device.request('');
    await _settle(tester);

    expect(find.byType(EntryFormPage), findsNothing);
  });

  test('o pedido é o mesmo dos dois lados, e o botão do widget o manda, '
      'com nome para o leitor de tela', () {
    const android = 'android/app/src/main';
    final activity = File('$android/kotlin/app/cajui/MainActivity.kt')
        .readAsStringSync();
    final widget = File('$android/kotlin/app/cajui/home/HomeWidget.kt')
        .readAsStringSync();
    final layout = File('$android/res/layout/home_widget.xml')
        .readAsStringSync();
    final strings = File('$android/res/values/strings.xml').readAsStringSync();

    expect(activity, contains('NEW_ENTRY_ROUTE = "${NewEntryShortcut.route}"'));
    expect(
      activity,
      contains('ACTION_NEW_ENTRY -> NoticeRouter.requestRoute(NEW_ENTRY_ROUTE'),
    );
    expect(widget, contains('R.id.home_new_entry'));
    expect(widget, contains('MainActivity.ACTION_NEW_ENTRY'));
    expect(layout, contains('@+id/home_new_entry'));
    expect(
      layout,
      contains('android:contentDescription="@string/home_widget_new_entry"'),
    );
    expect(
      strings,
      contains('<string name="home_widget_new_entry">Novo lançamento</string>'),
    );
  });
}
