import 'dart:io';

import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/debts/application/debts_service.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

final LedgerBook _catalog = DefaultCatalog.emptyBook;
final PaymentMethod _pix = _catalog.methodOf('pix');

void main() {
  late MemoryLedgerJournal journal;
  late ProviderContainer container;

  DebtsService debts() => container.read(debtsServiceProvider);
  Future<LedgerBook> book() => container.read(ledgerProvider.future);
  MonthOverview overview() => container.read(monthOverviewProvider)!;

  /// Um empréstimo de 12 parcelas de R$ 212,00, com 5 pagas e a próxima
  /// vencendo neste mês.
  Future<Debt> loan({int total = 12, int paid = 5, int cents = 21200}) async {
    final result = await debts().define(
      creditor: 'Empréstimo Banco X',
      kind: DebtKind.loan,
      installmentAmount: Money.fromCents(cents),
      totalInstallments: total,
      paidInstallments: paid,
      dueDay: 15,
      firstMonth: testToday.budgetMonth.addMonths(-paid),
    );
    return result.valueOrNull!;
  }

  setUp(() async {
    journal = MemoryLedgerJournal(samplePlanEvents);
    container = ProviderContainer(overrides: testOverrides(journal: journal));
    addTearDown(container.dispose);
    await book();
  });

  group('cadastrar (RN-501)', () {
    test('RN-501 · a dívida cadastrada entra no livro com o que falta e a '
        'previsão de quitação', () async {
      final debt = await loan();

      expect((await book()).debts.single.creditor, 'Empréstimo Banco X');
      expect(debt.remainingInstallments, 7);
      expect(debt.outstandingBalance.cents, 148400);
      // 5 pagas: a primeira caiu em abril, a última cai em março de 2027.
      expect(debt.payoffForecast, const BudgetMonth(2027, 3));
    });

    test(
      'E-DEBT-01 · pagas além do total é recusado, e nada é gravado',
      () async {
        final result = await debts().define(
          creditor: 'Empréstimo',
          kind: DebtKind.loan,
          installmentAmount: const Money.fromCents(10000),
          totalInstallments: 6,
          paidInstallments: 7,
          dueDay: 10,
          firstMonth: testToday.budgetMonth,
        );

        expect(result.failureOrNull, isA<PaidInstallmentsExceedTotal>());
        expect((await book()).debts, isEmpty);
      },
    );
  });

  group('a parcela no plano (RN-504)', () {
    test('RN-504 · a parcela do mês entra como compromisso e come a sobra '
        'planejada', () async {
      final before = overview().indicators.plannedResult;

      await loan();

      final after = overview().indicators.plannedResult;
      expect((before - after).cents, 21200);
      expect(
        (await book()).installmentsDueIn(testToday.budgetMonth).cents,
        21200,
      );
    });

    test(
      'RN-532 · dívida quitada não entra no plano do mês seguinte',
      () async {
        // Última parcela neste mês: 11 pagas de 12.
        await loan(paid: 11);
        final current = await book();

        expect(current.installmentsDueIn(testToday.budgetMonth).cents, 21200);
        expect(
          current.installmentsDueIn(testToday.budgetMonth.next),
          Money.zero,
        );
      },
    );
  });

  group('pagar a parcela (RN-520)', () {
    test('RN-520 · pagar é um lançamento do bloco de dívidas, e a dívida '
        'conta mais uma parcela paga', () async {
      final debt = await loan();

      final result = await debts().payInstallment(
        debt,
        method: _pix,
        on: testToday,
      );
      final current = await book();

      final entry = result.valueOrNull!;
      expect(current.categoryOf(entry.categoryId).block, Block.debt);
      expect(entry.description, 'Empréstimo Banco X · parcela 6 de 12');
      expect(entry.amount.cents, 21200);
      expect(current.debtOf(debt.id)!.paidInstallments, 6);
      expect(current.debtOf(debt.id)!.remainingInstallments, 6);
    });

    test(
      'a parcela paga sai do dinheiro do mês, e não do vale (RN-111)',
      () async {
        await debts().payInstallment(await loan(), method: _pix, on: testToday);

        final spent = (await book()).spentIn(testToday.budgetMonth);
        expect(spent.cash.cents, 21200);
        expect(spent.mealVoucher, Money.zero);
      },
    );

    test('RN-208 e RN-520 · cancelar o lançamento devolve a parcela ao que '
        'falta', () async {
      final debt = await loan();
      final entry = (await debts().payInstallment(
        debt,
        method: _pix,
        on: testToday,
      )).valueOrNull!;
      expect((await book()).debtOf(debt.id)!.paidInstallments, 6);

      await container
          .read(ledgerProvider.notifier)
          .cancel(entry.id, reason: 'Lancei errado e vou refazer');
      final current = await book();

      expect(current.debtOf(debt.id)!.paidInstallments, 5);
      expect(current.entries, isEmpty);
    });
  });

  group('terminar antes', () {
    test('RN-511 e RN-512 · o valor para quitar é o que o credor informou, '
        'com a data', () async {
      final debt = await loan();

      await debts().setPayoffQuote(debt, const Money.fromCents(130000));
      final quote = (await book()).debtOf(debt.id)!.payoffQuote!;

      expect(quote.amount.cents, 130000);
      expect(quote.quotedOn, testToday);
      expect(quote.isStaleOn(testToday), isFalse);
      expect(quote.isStaleOn(testToday.addDays(45)), isTrue);
    });

    test('RN-533 · a simulação é sobre o saldo nominal: 7 × 212 pagando 100 '
        'a mais por mês termina em 5 meses', () async {
      final debt = await loan();

      final simulation = PayoffSimulation.withExtra(
        debt,
        const Money.fromCents(10000),
      );

      expect(simulation.monthsToPayoff, 5);
      expect(simulation.monthsSaved, 2);
      expect(PayoffSimulation.basis, 'nominal');
    });
  });

  test('dívida e parcela paga voltam iguais do registro cifrado', () async {
    final directory = Directory.systemTemp.createTempSync('cajui-debts-');
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

    container = await open();
    final debt = await loan();
    await debts().setPayoffQuote(debt, const Money.fromCents(130000));
    await debts().payInstallment(
      (await book()).debtOf(debt.id)!,
      method: _pix,
      on: testToday,
    );

    final reopened = await (await open()).read(ledgerProvider.future);

    final back = reopened.debtOf(debt.id)!;
    expect(back.creditor, 'Empréstimo Banco X');
    expect(back.paidInstallments, 6);
    expect(back.kind, DebtKind.loan);
    expect(back.payoffQuote!.amount.cents, 130000);
    expect(reopened.entries.single.amount.cents, 21200);
  });

  test('o fato de dívida é gravado com o tipo do contrato', () async {
    await loan();

    expect(
      (await journal.readAll()).whereType<DebtDefined>().single.debt.dueDay,
      15,
    );
  });
}
