import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';
import '../notifications/fake_notice_device.dart';
import 'review_entries.dart';

Future<FakeNoticeDevice> _open(
  WidgetTester tester, {
  List<LedgerEvent>? events,
  String? route = 'review',
}) async {
  tester.view.physicalSize = const Size(400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final device = FakeNoticeDevice()..pendingRoute = route;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(journal: MemoryLedgerJournal(events ?? reviewWeek)),
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

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CajuiApp)));

Finder _review() => find.descendant(
  of: find.byType(CajuiScreen),
  matching: find.text('Revisão da semana'),
);

Finder _chip(String entryId, String category) => find.descendant(
  of: find.byKey(ValueKey(entryId)),
  matching: find.text(category),
);

void main() {
  testWidgets('RN-849 · o aviso de domingo abre a revisão, com os gastos da '
      'semana que pedem um olhar', (tester) async {
    await _open(tester);

    expect(_review(), findsOneWidget);
    expect(find.textContaining('2 gastos da semana'), findsOneWidget);
    expect(find.text('Mercado Bom Preco'), findsOneWidget);
    expect(find.text('Pão de queijo'), findsOneWidget);
    expect(find.textContaining('lançado pela notificação'), findsOneWidget);
  });

  testWidgets('RN-871 · um toque na categoria certa corrige o gasto e o tira '
      'da lista', (tester) async {
    await _open(tester);

    await tester.tap(_chip('outros', 'Padaria'));
    await _settle(tester);

    final book = _container(tester).read(ledgerProvider).value!;
    expect(book.entryOf('outros')!.categoryId, 'bakery');
    expect(find.byKey(const ValueKey('outros')), findsNothing);
    expect(find.textContaining('Um gasto da semana'), findsOneWidget);
  });

  testWidgets('RN-871 · tocar na categoria que ele já tem confirma, sem '
      'gravar correção', (tester) async {
    await _open(tester);

    await tester.tap(_chip('auto', 'Mercado'));
    await _settle(tester);

    final book = _container(tester).read(ledgerProvider).value!;
    expect(book.entryOf('auto')!.revisedAt, isNull);
    expect(find.byKey(const ValueKey('auto')), findsNothing);
  });

  testWidgets('RN-871 · "Está tudo certo" tira o resto da lista e fecha a '
      'revisão', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Está tudo certo'));
    await _settle(tester);

    expect(_review(), findsNothing);
    expect(_container(tester).read(reviewItemsProvider), isEmpty);
  });

  testWidgets('sem nada para revisar, a tela diz que está tudo revisto', (
    tester,
  ) async {
    await _open(tester, events: const []);

    expect(find.text('Tudo revisto'), findsOneWidget);
    expect(find.text('Está tudo certo'), findsNothing);
  });

  testWidgets('RN-849 · o aviso tocado com o app aberto também abre a '
      'revisão', (tester) async {
    final device = await _open(tester, route: null);
    expect(_review(), findsNothing);

    device.request('review');
    await _settle(tester);

    expect(_review(), findsOneWidget);
  });
}
