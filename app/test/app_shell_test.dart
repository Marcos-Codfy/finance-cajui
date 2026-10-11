import 'package:cajui/src/app/cajui_app.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/home_navigation.dart';
import 'support/mute_player.dart';
import 'support/test_scope.dart';

Future<MutePlayer> _open(WidgetTester tester) async {
  // Alto o bastante para o Início e os ajustes caberem inteiros: a lista é
  // preguiçosa e não constrói o que está fora da tela.
  tester.view.physicalSize = const Size(400, 2000);
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

/// O título da tela à vista: a outra aba fica montada, mas fora de cena, e
/// o `find` comum não a enxerga.
Finder _screen(String title) =>
    find.descendant(of: find.byType(CajuiScreen), matching: find.text(title));

Finder _bar(String label) =>
    find.descendant(of: find.byType(CajuiNavBar), matching: find.text(label));

void main() {
  testWidgets('abre na conversa, com as duas áreas na barra (sugestões 3 e '
      '5 do dono)', (tester) async {
    await _open(tester);

    expect(find.textContaining(AssistantIdentity.name), findsWidgets);
    for (final label in ['Conversar', 'Início']) {
      expect(_bar(label), findsOneWidget, reason: label);
    }
    expect(_bar('Lançamentos'), findsNothing);
    expect(_bar('Ajustes'), findsNothing);
  });

  testWidgets('o Início tem o mês e as portas para o resto', (tester) async {
    await _open(tester);

    await tester.tap(find.bySemanticsLabel('Início'));
    await settleAfterTap(tester);

    expect(_screen('Setembro'), findsOneWidget);
    for (final door in [
      'Meu mês',
      'Lançamentos',
      'Minhas contas',
      'Cartões',
      'Dívidas',
      'Mês a mês',
    ]) {
      expect(find.text(door), findsOneWidget, reason: door);
    }
  });

  testWidgets('lançamentos vazios dizem o que fazer, e não "sem dados"', (
    tester,
  ) async {
    await _open(tester);

    await openFromHome(tester, 'Lançamentos');

    expect(_screen('Lançamentos'), findsOneWidget);
    expect(find.text('Nada lançado ainda'), findsOneWidget);
  });

  testWidgets('o som nasce desligado e só carrega quando é ligado', (
    tester,
  ) async {
    final player = await _open(tester);
    await openFromHome(tester, 'Ajustes');

    expect(player.preloads, 0);
    expect(player.played, isEmpty);

    await tester.tap(find.bySemanticsLabel('Sons').last);
    await tester.pump();

    expect(player.preloads, 1);
    // A própria chave que liga os sons já soa ao ligar: o retorno sensorial
    // sai **depois** da ação, obedecendo à escolha nova.
    expect(player.played, [CajuiSound.toggleOn]);
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
