import 'dart:async';

import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/fake_uplink.dart';
import '../../support/home_navigation.dart';
import '../../support/test_scope.dart';

Future<void> _open(
  WidgetTester tester,
  LedgerUplink uplink, {
  FakeHouseholdKey? keys,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(uplink: uplink, householdKey: keys),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  // Abre direto: a porta do Início depende de o livro já ter chegado, e o
  // que se confere aqui é só a tela de Ajustes.
  unawaited(SettingsPage.open(tester.element(find.byType(CajuiScreen).first)));
  await settleAfterTap(tester);
}

void main() {
  testWidgets('ADR-027 · no celular, Ajustes mostra a chave da casa', (
    tester,
  ) async {
    await _open(tester, FakeUplink());

    expect(find.text('Chave da casa'), findsOneWidget);
    expect(find.text('Sair'), findsNothing);
  });

  testWidgets('ADR-027 · na consulta, Ajustes não mostra a sessão do código '
      'como se fosse a chave da casa', (tester) async {
    await _open(tester, const NoLedgerUplink());

    expect(find.text('Chave da casa'), findsNothing);
  });

  testWidgets('ADR-027 · na consulta, "Sair" esquece a entrada e volta à '
      'tela de entrada', (tester) async {
    final keys = FakeHouseholdKey();
    await _open(tester, const NoLedgerUplink(), keys: keys);

    await tester.tap(find.text('Sair'));
    await settleAfterTap(tester);

    expect(keys.key, isNull);
    expect(find.text('Código ou chave da casa'), findsOneWidget);
    expect(find.text('Ajustes'), findsNothing);
  });
}
