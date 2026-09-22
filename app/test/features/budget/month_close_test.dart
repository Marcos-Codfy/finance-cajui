import 'package:cajui/src/features/budget/application/month_closing.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

final LedgerBook _catalog = DefaultCatalog.emptyBook;

/// Agosto: o mês que já terminou quando hoje é 20 de setembro de 2026.
final BudgetMonth _august = testToday.budgetMonth.previous;
final LocalDate _inAugust = LocalDate(2026, 8, 14);

void main() {
  late MemoryLedgerJournal journal;
  late ProviderContainer container;

  LedgerController ledger() => container.read(ledgerProvider.notifier);
  MonthClosing closing() => container.read(monthClosingProvider);
  Future<LedgerBook> book() => container.read(ledgerProvider.future);
  Future<List<MonthClosed>> closings() async =>
      (await journal.readAll()).whereType<MonthClosed>().toList();

  Future<Entry> spend(int cents, {LocalDate? on}) async {
    final result = await ledger().record(
      EntryDraft(
        amountCents: cents,
        description: 'Mercado do mês',
        category: _catalog.categoryOf('groceries'),
        method: _catalog.methodOf('pix'),
        occurredOn: on ?? _inAugust,
      ),
    );
    return result.valueOrNull!;
  }

  setUp(() async {
    journal = MemoryLedgerJournal(samplePlanEvents);
    container = ProviderContainer(overrides: testOverrides(journal: journal));
    addTearDown(container.dispose);
    await book();
  });

  test('RN-442 · fechar um mês que ainda não terminou é recusado, e nada é '
      'gravado', () async {
    final result = await closing().close(testToday.budgetMonth);

    final failure = result.failureOrNull! as MonthNotOver;
    expect(failure.closableFrom, LocalDate(2026, 10, 1));
    expect(await closings(), isEmpty);
  });

  test('RN-623 · o resultado é a renda que entrou menos as despesas em '
      'dinheiro do mês', () async {
    await ledger().receiveIncome(
      tender: Tender.cash,
      amount: const Money.fromCents(300000),
      receivedOn: _inAugust,
    );
    await spend(45000);

    final close = (await closing().close(_august)).valueOrNull!;

    expect(close.month, _august);
    expect(close.revision, 1);
    expect(close.cashResult.cents, 255000);
    expect(close.closedOn, testToday);
  });

  test(
    'RN-111 · o que saiu do vale não entra no resultado em dinheiro',
    () async {
      await ledger().receiveIncome(
        tender: Tender.cash,
        amount: const Money.fromCents(100000),
        receivedOn: _inAugust,
      );
      await ledger().record(
        EntryDraft(
          amountCents: 20000,
          description: 'Feira',
          category: _catalog.categoryOf('groceries'),
          method: _catalog.methodOf('voucher'),
          occurredOn: _inAugust,
        ),
      );

      final close = (await closing().close(_august)).valueOrNull!;

      expect(close.cashResult.cents, 100000);
    },
  );

  test('RN-440 · mudar o plano depois não altera o mês fechado', () async {
    await spend(30000);
    final close = (await closing().close(_august)).valueOrNull!;

    await ledger().definePlan(
      samplePlan.withMoney(cashIncome: const Money.fromCents(900000)),
    );

    expect((await book()).closeOf(_august)!.cashResult, close.cashResult);
    expect(await closings(), hasLength(1));
  });

  group('lançamento tardio (RN-441)', () {
    test('RN-441 · lançamento com data no mês fechado gera revisão, e a '
        'anterior continua no registro', () async {
      await closing().close(_august);
      final first = (await book()).closeOf(_august)!;

      await spend(4200);
      final current = (await book()).closeOf(_august)!;

      expect(current.revision, 2);
      expect(current.differenceFrom(first).cents, -4200);
      expect(await closings(), hasLength(2));
      expect((await closings()).first.close.revision, 1);
    });

    test('RN-252 · o lançamento tardio é aceito, e não recusado', () async {
      await closing().close(_august);

      final result = await ledger().record(
        EntryDraft(
          amountCents: 4200,
          description: 'Padaria',
          category: _catalog.categoryOf('bakery'),
          method: _catalog.methodOf('pix'),
          occurredOn: _inAugust,
        ),
      );

      expect(result.isOk, isTrue);
      expect((await book()).entriesIn(_august), hasLength(1));
    });

    test(
      'lançamento no mês em curso não mexe no fechamento de agosto',
      () async {
        await closing().close(_august);

        await spend(4200, on: testToday);

        expect((await book()).closeOf(_august)!.revision, 1);
        expect(await closings(), hasLength(1));
      },
    );

    test(
      'estorno e cancelamento no mês fechado também geram revisão',
      () async {
        final entry = await spend(30000);
        await closing().close(_august);

        await ledger().reverse(
          entry: entry,
          paymentMethodId: 'pix',
          amount: const Money.fromCents(10000),
          occurredOn: _inAugust,
        );
        expect((await book()).closeOf(_august)!.revision, 2);

        await ledger().cancel(entry.id, reason: 'Lancei duas vezes');

        expect((await book()).closeOf(_august)!.revision, 3);
        expect((await book()).closeOf(_august)!.cashResult, Money.zero);
      },
    );
  });

  test(
    'RN-443 · a falta do mês fechado não vira dívida do mês seguinte',
    () async {
      await spend(500000);
      final close = (await closing().close(_august)).valueOrNull!;
      expect(close.cashResult.isNegative, isTrue);

      final overview = container.read(monthOverviewProvider)!;

      // Setembro continua com o plano de setembro: a falta de agosto é dita,
      // nunca descontada por conta própria.
      expect(overview.plan.cashIncome.cents, 320000);
      expect(overview.indicators.plannedResult.cents, 122800);
    },
  );

  test('fechar duas vezes não cria revisão nova', () async {
    await closing().close(_august);
    await closing().close(_august);

    expect(await closings(), hasLength(1));
  });
}
