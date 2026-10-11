import 'dart:io';

import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

void main() {
  late ProviderContainer container;

  LedgerController ledger() => container.read(ledgerProvider.notifier);
  IncomeService income() => container.read(incomeServiceProvider);
  Future<LedgerBook> book() => container.read(ledgerProvider.future);
  Finances finances() => container.read(financesProvider)!;

  setUp(() async {
    container = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal(samplePlanEvents)),
    );
    addTearDown(container.dispose);
    await book();
  });

  test('RN-120 · saldo do vale = saldo + créditos − compras no vale: 50 + 600 '
      '− 480 = 170', () async {
    await income().setVoucherBalance(
      const Money.fromCents(5000),
      reason: 'saldo inicial do exemplo',
    );

    await income().receiveIncome(
      tender: Tender.mealVoucher,
      amount: const Money.fromCents(60000),
      receivedOn: testToday,
    );
    final current = await book();
    await ledger().record(
      EntryDraft(
        amountCents: 48000,
        description: 'Mercado do mês',
        category: current.categoryOf('groceries'),
        method: current.methodOf('voucher'),
        occurredOn: testToday,
      ),
    );

    expect((await book()).voucher.balance.cents, 17000);
  });

  test('RN-131 · o valor recebido vale no lugar do esperado, no mês em que '
      'foi recebido', () async {
    expect(finances().cashIncomeIn(testToday.budgetMonth).cents, 320000);

    await income().receiveIncome(
      tender: Tender.cash,
      amount: const Money.fromCents(231000),
      receivedOn: testToday,
      salaryId: BudgetPlan.firstSalaryId,
    );

    expect(finances().cashIncomeIn(testToday.budgetMonth).cents, 231000);
    expect(finances().cashIncomeIn(const BudgetMonth(2026, 10)).cents, 320000);
  });

  test('RN-133 · entrada avulsa soma no mês em que entrou, e não aparece no '
      'mês seguinte', () async {
    await income().receiveIncome(
      tender: Tender.cash,
      amount: const Money.fromCents(15000),
      receivedOn: testToday,
    );

    expect(finances().cashIncomeIn(testToday.budgetMonth).cents, 335000);
    expect(finances().cashIncomeIn(const BudgetMonth(2026, 10)).cents, 320000);
  });

  test('RN-132 e RN-111 · recebimento não é lançamento, e o vale não entra '
      'na renda em dinheiro', () async {
    await income().receiveIncome(
      tender: Tender.mealVoucher,
      amount: const Money.fromCents(60000),
      receivedOn: testToday,
    );
    final current = await book();

    expect(current.entries, isEmpty);
    expect(current.spentIn(testToday.budgetMonth), TenderAmounts.zero);
    expect(finances().cashIncomeIn(testToday.budgetMonth).cents, 320000);
  });

  test('valor zero não gera fato', () async {
    await income().receiveIncome(
      tender: Tender.cash,
      amount: Money.zero,
      receivedOn: testToday,
    );

    expect((await book()).receipts, isEmpty);
  });

  test('a renda recebida volta igual do registro cifrado', () async {
    final directory = Directory.systemTemp.createTempSync('cajui-income-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Future<ProviderContainer> open() async {
      final opened = ProviderContainer(
        overrides: testOverrides(
          journal: EventStoreLedgerJournal(
            store: await openEventStoreAt(directory),
            codec: LedgerEventCodec(
              categoryOf: DefaultCatalog.emptyBook.categoryOf,
            ),
          ),
        ),
      );
      addTearDown(opened.dispose);
      return opened;
    }

    container = await open();
    await income().receiveIncome(
      tender: Tender.mealVoucher,
      amount: const Money.fromCents(60000),
      receivedOn: testToday,
    );

    final reopened = await (await open()).read(ledgerProvider.future);

    expect(reopened.receipts.single.tender, Tender.mealVoucher);
    expect(reopened.voucher.balance.cents, 60000);
  });
}
