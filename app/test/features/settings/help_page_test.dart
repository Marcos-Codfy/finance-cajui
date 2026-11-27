import 'package:cajui/src/app/cajui_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';
import '../../support/home_navigation.dart';
import '../../support/test_scope.dart';

void main() {
  testWidgets('a ajuda abre dos Ajustes, e cada assunto mostra a explicação '
      'só quando é aberto', (tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(uplink: FakeUplink()),
        child: const CajuiApp(),
      ),
    );
    await tester.pump();
    await openFromHome(tester, 'Ajustes');

    await tester.tap(find.text('Como o Cajui conta'));
    await settleAfterTap(tester);
    expect(find.text('Vale alimentação'), findsOneWidget);
    expect(find.textContaining('nunca se soma ao dinheiro'), findsNothing);

    await tester.tap(find.text('Vale alimentação'));
    await settleAfterTap(tester);
    expect(find.textContaining('nunca se soma ao dinheiro'), findsOneWidget);
  });
}
