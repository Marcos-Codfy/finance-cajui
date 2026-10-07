import 'package:cajui/src/app/cajui_app.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mute_player.dart';
import 'support/test_scope.dart';

Future<MutePlayer> _open(WidgetTester tester) async {
  // Alto o bastante para a lista de ajustes inteira caber: ela é preguiçosa
  // e não constrói o que está fora da tela.
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final player = MutePlayer();
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(player: player),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  return player;
}

/// O título da tela à vista: as telas das outras abas ficam montadas, mas
/// fora de cena, e o `find` comum não as enxerga.
Finder _screen(String title) =>
    find.descendant(of: find.byType(CajuiScreen), matching: find.text(title));

void main() {
  testWidgets('abre no painel, com as quatro áreas na barra', (tester) async {
    await _open(tester);

    // O painel já nasce com o mês no título: não há mais tela de "comece".
    expect(_screen('Setembro'), findsOneWidget);
    for (final label in ['Painel', 'Lançamentos', 'Assistente', 'Ajustes']) {
      expect(
        find.descendant(
          of: find.byType(CajuiNavBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('tocar numa área da barra leva até ela', (tester) async {
    await _open(tester);

    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pump();

    expect(_screen('Ajustes'), findsOneWidget);
    expect(_screen('Setembro'), findsNothing);
  });

  testWidgets('lançamentos vazios dizem o que fazer, e não "sem dados"', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.bySemanticsLabel('Lançamentos'));
    await tester.pump();

    expect(_screen('Lançamentos'), findsOneWidget);
    expect(find.text('Nada lançado ainda'), findsOneWidget);
  });

  testWidgets('o som nasce desligado e só carrega quando é ligado', (
    tester,
  ) async {
    final player = await _open(tester);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pump();

    expect(player.preloads, 0);
    expect(player.played, isEmpty);

    await tester.tap(find.bySemanticsLabel('Sons').last);
    await tester.pump();

    expect(player.preloads, 1);
    // A própria chave que liga os sons já soa ao ligar: o retorno sensorial
    // sai **depois** da ação, obedecendo à escolha nova. Antes ficava muda
    // ao ligar e só soava ao desligar.
    expect(player.played, [CajuiSound.toggleOn]);
    await tester.tap(find.bySemanticsLabel('Painel'));
    expect(player.played.length, greaterThan(1));
  });

  testWidgets('abre no claro mesmo com o aparelho no escuro: o tema é '
      'escolha de quem usa, nos ajustes', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _open(tester);

    final theme = CajuiTheme.of(tester.element(find.byType(CajuiNavBar)));
    expect(theme.colors.brightness, Brightness.light);
  });
}
