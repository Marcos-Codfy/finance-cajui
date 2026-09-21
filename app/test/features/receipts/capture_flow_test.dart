import 'dart:io';

import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/infrastructure/event_store_capture_shelf.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/pix_receipt.dart';
import '../../support/test_scope.dart';

/// Deixa leitura, classificação e troca de tela terminarem. `pumpAndSettle`
/// não serve: os pontos de "carregando" pulsam sem parar.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('UC-CAPT-01 · Pix compartilhado: a conferência abre por cima do '
      'app, já preenchida, e só lança com o toque da pessoa', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final inbox = FakeInbox();
    final journal = MemoryLedgerJournal();
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(inbox: inbox, journal: journal),
        child: const CajuiApp(),
      ),
    );
    await _settle(tester);

    inbox.share(const [SharedText(id: 'c1', text: pixReceiptText)]);
    await _settle(tester);

    expect(find.text('Conferir comprovante'), findsOneWidget);
    expect(find.text('6,00'), findsOneWidget);
    expect(
      find.text('LANCHONETE E RESTAURANTE SABOR DA PRACA'),
      findsOneWidget,
    );
    expect(find.text('Pix'), findsOneWidget);
    expect(await journal.readAll(), isEmpty, reason: 'RN-795: nada gravado');

    await tester.tap(find.text('Categoria'));
    await _settle(tester);
    await tester.tap(find.text('Restaurante e lanche'));
    await _settle(tester);
    await tester.tap(find.text('Lançar'));
    await _settle(tester);

    expect(find.text('Conferir comprovante'), findsNothing);
    expect(await journal.readAll(), hasLength(1));
  });

  test('T-07 · o texto do comprovante guardado para depois não fica em claro '
      'no aparelho, e volta igual ao reabrir', () async {
    final directory = Directory.systemTemp.createTempSync('cajui-shelf-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final shelf = EventStoreCaptureShelf(await openEventStoreAt(directory));
    await shelf.defer(
      PendingCapture(id: 'c1', receivedOn: testToday, text: pixReceiptText),
    );
    await shelf.learn(merchant: 'Padaria Central Ltda', categoryId: 'bakery');

    final onDisk = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.jsonl'))
        .map((file) => file.readAsStringSync())
        .join();
    final reopened = EventStoreCaptureShelf(await openEventStoreAt(directory));

    expect(onDisk, isNot(contains('LANCHONETE')));
    expect((await reopened.pending()).single.text, pixReceiptText);
    expect(await reopened.learnedRules(), {'padaria central': 'bakery'});

    await reopened.close('c1');
    expect(await reopened.pending(), isEmpty);
  });
}
