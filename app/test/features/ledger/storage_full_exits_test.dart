import 'package:cajui/src/core/device/storage_settings.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistence/persistence.dart';

import '../../support/test_scope.dart';

/// O disco cheio: o livro não abre.
final class _FullDisk implements LedgerJournal {
  @override
  Future<List<LedgerEvent>> readAll() async =>
      throw const StorageFullException('/dados');

  @override
  Future<void> append(LedgerEvent event) async =>
      throw const StorageFullException('/dados');
}

final class _Settings implements StorageSettings {
  int opened = 0;

  @override
  Future<void> open() async => opened++;
}

void main() {
  testWidgets('E-STORAGE-01 · sem espaço, Lançamentos diz o que falta '
      'guardar e oferece abrir o armazenamento e tentar de novo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = _Settings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(journal: _FullDisk()),
          storageSettingsProvider.overrideWithValue(settings),
        ],
        child: WidgetsApp(
          color: const Color(0xFFFFFFFF),
          builder: (context, _) => CajuiAppSurface(
            theme: CajuiThemeData.light(),
            feedback: const SilentFeedback(),
            child: const EntriesPage(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('os lançamentos novos'), findsOneWidget);
    expect(find.textContaining('{item}'), findsNothing);
    await tester.tap(find.text('Abrir armazenamento'));
    await tester.pump();
    expect(settings.opened, 1);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });
}
