import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// A cor de fundo que o app está pintando agora.
Color _background(WidgetTester tester) {
  final surface = tester.widget<CajuiAppSurface>(
    find.byType(CajuiAppSurface).first,
  );
  return surface.theme.colors.surface.base;
}

Future<void> _open(WidgetTester tester, {required Brightness device}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = device;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal()),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('o app abre no tema claro mesmo com o aparelho no escuro', (
    tester,
  ) async {
    await _open(tester, device: Brightness.dark);

    expect(_background(tester), CajuiThemeData.light().colors.surface.base);
  });

  testWidgets('o tema escuro entra quando a pessoa liga nos ajustes', (
    tester,
  ) async {
    await _open(tester, device: Brightness.light);

    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel('Tema escuro'));
    await _settle(tester);

    expect(_background(tester), CajuiThemeData.dark().colors.surface.base);
  });
}
