import 'dart:io';

import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';

Entry _groceries() {
  final book = DefaultCatalog.emptyBook;
  return Entry.create(
    id: 'e1',
    description: 'Mercado Boa Compra',
    amount: const Money.fromCents(8600),
    occurredOn: LocalDate(2026, 9, 12),
    category: book.categoryOf('groceries'),
    today: testToday,
    paymentLines: [
      book.methodOf('voucher').line(const Money.fromCents(3000)),
      book.methodOf('pix').line(const Money.fromCents(5600)),
    ],
  ).valueOrNull!;
}

/// O livro sobre o registro cifrado da pasta [directory], como o app monta.
Future<LedgerJournal> openLedgerJournalAt(Directory directory) async {
  return EventStoreLedgerJournal(
    store: await openEventStoreAt(directory),
    codec: LedgerEventCodec(categoryOf: DefaultCatalog.emptyBook.categoryOf),
  );
}

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('cajui-app-');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  test('o que foi gravado volta igual depois de fechar e abrir', () async {
    final journal = await openLedgerJournalAt(directory);
    await journal.append(EntryRecorded(_groceries()));
    await journal.append(
      VoucherBalanceAdjusted(
        id: 'voucher-adjust-1',
        adjustment: const Money.fromCents(-790),
        on: testToday,
        reason: 'saldo da operadora',
      ),
    );

    final reopened = await openLedgerJournalAt(directory);
    final [first, second] = await reopened.readAll();

    final entry = (first as EntryRecorded).entry;
    expect(entry.description, 'Mercado Boa Compra');
    expect(entry.paidByTender.mealVoucher.cents, 3000);
    expect(entry.paidByTender.cash.cents, 5600);
    expect((second as VoucherBalanceAdjusted).adjustment.cents, -790);
    expect(second.on, testToday);
  });

  test('T-07 · o arquivo no aparelho não traz o lançamento em claro', () async {
    final journal = await openLedgerJournalAt(directory);
    await journal.append(EntryRecorded(_groceries()));

    final onDisk = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.jsonl'))
        .map((file) => file.readAsStringSync())
        .join();

    expect(onDisk, isNotEmpty);
    expect(onDisk, isNot(contains('Mercado')));
    expect(onDisk, isNot(contains('8600')));
  });

  test('gravar o mesmo fato duas vezes não duplica', () async {
    final journal = await openLedgerJournalAt(directory);
    await journal.append(EntryRecorded(_groceries()));
    await journal.append(EntryRecorded(_groceries()));

    expect(await journal.readAll(), hasLength(1));
  });

  test('fato de um tipo que esta versão não conhece é pulado', () {
    final codec = LedgerEventCodec(
      categoryOf: DefaultCatalog.emptyBook.categoryOf,
    );

    expect(codec.decode('x', 'budget.planned', const {}), isNull);
  });
}
