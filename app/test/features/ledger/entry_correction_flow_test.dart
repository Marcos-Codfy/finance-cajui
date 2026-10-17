import 'dart:io';

import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

final LedgerBook _catalog = DefaultCatalog.emptyBook;

/// Cinema de 120,00 no Pix, lançado hoje como lazer.
final Entry _cinema = Entry.create(
  id: 'cinema',
  description: 'Cinema',
  amount: const Money.fromCents(12000),
  occurredOn: testToday,
  category: _catalog.categoryOf('leisure'),
  paymentLines: [_catalog.methodOf('pix').line(const Money.fromCents(12000))],
  today: testToday,
).valueOrNull!;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

Future<MemoryLedgerJournal> _openCinema(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal([EntryRecorded(_cinema)]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Lançamentos');
  await _tap(tester, find.text('Cinema'));
  return journal;
}

void main() {
  testWidgets('RN-208 · corrigir em dois toques: a categoria muda na lista, e '
      'o registro guarda o original e a correção', (tester) async {
    final journal = await _openCinema(tester);

    await _tap(tester, find.text('Corrigir'));
    expect(find.text('Corrigir lançamento'), findsOneWidget);
    await _tap(tester, find.text('Categoria'));
    await _tap(tester, find.text('Transporte'));
    await _tap(tester, find.text('Guardar correção'));
    await _tap(tester, find.bySemanticsLabel('Voltar'));

    expect(find.text('Transporte · Pix · hoje'), findsOneWidget);
    final facts = await journal.readAll();
    expect(facts.whereType<EntryRecorded>().single.entry.categoryId, 'leisure');
    expect(facts.whereType<EntryCorrected>().single.reason, 'categoria');
  });

  testWidgets('RN-209 · o estorno abre com o valor inteiro, e o que voltou '
      'aparece no lançamento', (tester) async {
    final journal = await _openCinema(tester);

    await _tap(tester, find.text('Registrar estorno'));
    await _tap(tester, find.text('Registrar estorno').last);

    expect(find.text('O que voltou'), findsOneWidget);
    expect(find.text('Voltou por Pix'), findsOneWidget);
    // Voltou tudo: não há mais o que estornar (RN-210).
    expect(find.text('Registrar estorno'), findsNothing);
    final reversal = (await journal.readAll()).whereType<EntryReversed>();
    expect(reversal.single.reversal.line.amount.cents, 12000);

    // Na lista, a compra diz que o dinheiro voltou: o gasto do mês caiu, e a
    // linha explica por quê.
    await _tap(tester, find.bySemanticsLabel('Voltar'));
    expect(find.textContaining(r'Lazer · Pix · hoje · voltou R$'), findsOne);
  });

  testWidgets('RN-208 · cancelar é dois toques no mesmo botão, sem tela: o '
      'lançamento sai da lista, e o fato original continua no registro', (
    tester,
  ) async {
    final journal = await _openCinema(tester);

    await _tap(tester, find.text('Cancelar lançamento'));
    expect(find.text('Confirmar o cancelamento'), findsOneWidget);
    await _tap(tester, find.text('Manter'));
    expect(find.text('Confirmar o cancelamento'), findsNothing);
    expect(await journal.readAll(), hasLength(1), reason: 'manter não grava');

    await _tap(tester, find.text('Cancelar lançamento'));
    await _tap(tester, find.text('Confirmar o cancelamento'));

    expect(find.text('Nada lançado ainda'), findsOneWidget);
    final facts = await journal.readAll();
    expect(facts.whereType<EntryRecorded>(), hasLength(1));
    expect(
      facts.whereType<EntryCancelled>().single.reason,
      'Cancelado pela pessoa',
    );
  });

  test(
    'correção, estorno e cancelamento voltam iguais do registro cifrado',
    () async {
      final directory = Directory.systemTemp.createTempSync('cajui-facts-');
      addTearDown(() => directory.deleteSync(recursive: true));
      Future<ProviderContainer> open() async {
        final opened = ProviderContainer(
          overrides: testOverrides(
            journal: EventStoreLedgerJournal(
              store: await openEventStoreAt(directory),
              codec: LedgerEventCodec(categoryOf: _catalog.categoryOf),
            ),
          ),
        );
        addTearDown(opened.dispose);
        return opened;
      }

      final first = await open();
      final ledger = first.read(ledgerProvider.notifier);
      EntryDraft draft(String description) => EntryDraft(
        amountCents: 12000,
        description: description,
        category: _catalog.categoryOf('leisure'),
        method: _catalog.methodOf('pix'),
        occurredOn: testToday,
      );
      final kept = (await ledger.record(draft('Cinema'))).valueOrNull!;
      final gone = (await ledger.record(draft('Teatro'))).valueOrNull!;
      await ledger.correct(
        EntryDraft.correcting(
          kept,
          category: _catalog.categoryOf('transport'),
          methodOf: _catalog.methodOf,
        ),
      );
      await ledger.reverse(
        entry: kept,
        paymentMethodId: 'pix',
        amount: const Money.fromCents(2000),
        occurredOn: testToday,
      );
      await ledger.cancel(gone.id, reason: 'Lancei duas vezes');

      final reopened = await (await open()).read(ledgerProvider.future);

      expect(reopened.entries.single.categoryId, 'transport');
      expect(reopened.reversals.single.line.amount.cents, 2000);
      expect(reopened.spentIn(testToday.budgetMonth).cash.cents, 10000);
    },
  );
}
