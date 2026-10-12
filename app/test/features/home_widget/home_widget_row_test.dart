import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/home_widget/application/home_screen.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/test_scope.dart';

/// Uma tela inicial de mentira: diz onde o widget está e, quando pedem,
/// "põe" — como o launcher faz depois que a pessoa confirma.
final class _Launcher implements HomeScreen {
  new(this.current);

  WidgetPlacement current;
  int pins = 0;

  @override
  Future<void> publish(HomeSnapshot snapshot) async {}

  @override
  Future<WidgetPlacement> placement() async => current;

  @override
  Future<void> pin() async {
    pins++;
    current = WidgetPlacement.placed;
  }
}

Future<void> _openSettings(WidgetTester tester, _Launcher launcher) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(),
        homeScreenProvider.overrideWithValue(launcher),
      ],
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Ajustes');
}

void main() {
  testWidgets('ADR-025 · sem o widget na tela, um toque pede ao launcher, e '
      'a linha passa a dizer que está lá', (tester) async {
    final launcher = _Launcher(WidgetPlacement.absent);
    await _openSettings(tester, launcher);

    expect(find.text('Pôr na tela'), findsOneWidget);
    await tester.tap(find.text('Widget na tela inicial'));
    await settleAfterTap(tester);

    expect(launcher.pins, 1);
    expect(find.text('Na tela'), findsOneWidget);
  });

  testWidgets('com o widget já na tela, a linha só informa', (tester) async {
    final launcher = _Launcher(WidgetPlacement.placed);
    await _openSettings(tester, launcher);

    await tester.tap(find.text('Widget na tela inicial'));
    await settleAfterTap(tester);

    expect(launcher.pins, 0);
    expect(find.textContaining('Já está na tela inicial'), findsOneWidget);
  });

  testWidgets('launcher que não aceita o pedido: o caminho à mão', (
    tester,
  ) async {
    await _openSettings(tester, _Launcher(WidgetPlacement.manual));

    expect(find.textContaining('abra Widgets'), findsOneWidget);
  });

  testWidgets('na web não há tela inicial: a linha não aparece', (
    tester,
  ) async {
    await _openSettings(tester, _Launcher(WidgetPlacement.unavailable));

    expect(find.text('Widget na tela inicial'), findsNothing);
  });
}
