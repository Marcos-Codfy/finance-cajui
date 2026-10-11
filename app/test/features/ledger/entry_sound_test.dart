import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/settings/event_store_preferences.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/mute_player.dart';
import '../../support/test_scope.dart';

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('escolha 4 · lançar soa a semente, e o botão não soa por cima '
      'dela', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final preferences = EventStorePreferences(MemoryEventStore());
    await preferences.update((current) => current.copyWith(soundEnabled: true));
    final player = MutePlayer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(
          journal: MemoryLedgerJournal(),
          player: player,
          preferences: preferences,
        ),
        child: const CajuiApp(),
      ),
    );
    await tester.pump();
    await openFromHome(tester, 'Lançamentos');
    await tester.tap(find.text('Lançar'));
    await settleAfterTap(tester);
    await tester.enterText(_field('Valor'), '850');
    await settleAfterTap(tester);
    player.played.clear();

    await tester.tap(find.text('Lançar'));
    await settleAfterTap(tester);

    expect(player.played, contains(CajuiSound.entrySaved));
    expect(player.played, isNot(contains(CajuiSound.tap)));
  });
}
