import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

final LedgerBook _catalog = DefaultCatalog.emptyBook;
final PaymentMethod _voucher = _catalog.methodOf('voucher');

EntryDraft _draft({
  int cents = 12000,
  String category = 'leisure',
  PaymentMethod? method,
}) => EntryDraft(
  amountCents: cents,
  description: 'Cinema',
  category: _catalog.categoryOf(category),
  method: method ?? _catalog.methodOf('pix'),
  occurredOn: testToday,
);

void main() {
  late MemoryLedgerJournal journal;
  late ProviderContainer container;

  LedgerController ledger() => container.read(ledgerProvider.notifier);
  Future<LedgerBook> book() => container.read(ledgerProvider.future);
  Future<List<LedgerEvent>> facts() => journal.readAll();

  /// Lança [draft] e devolve o rascunho que abre a correção dele.
  Future<EntryDraft> recorded(EntryDraft draft) async {
    final entry = (await ledger().record(draft)).valueOrNull!;
    final current = await book();
    return EntryDraft.correcting(
      entry,
      category: current.categoryOf(entry.categoryId),
      methodOf: current.methodOf,
    );
  }

  setUp(() async {
    journal = MemoryLedgerJournal(samplePlanEvents);
    container = ProviderContainer(overrides: testOverrides(journal: journal));
    addTearDown(container.dispose);
    await book();
  });

  group('corrigir (RN-208)', () {
    test('RN-208 · trocar a categoria vale em toda visão, e o original fica no '
        'registro com o que mudou', () async {
      final open = await recorded(_draft());

      final result = await ledger().correct(
        open.copyWith(category: _catalog.categoryOf('transport')),
      );

      expect(result.isOk, isTrue);
      expect((await book()).entries.single.categoryId, 'transport');
      final kept = (await facts()).whereType<EntryRecorded>().single;
      final correction = (await facts()).whereType<EntryCorrected>().single;
      expect(kept.entry.categoryId, 'leisure');
      expect(correction.reason, 'categoria');
      expect(correction.on, testToday);
    });

    test('RN-208 · correção que não muda nada não grava fato', () async {
      final open = await recorded(_draft());

      await ledger().correct(open);

      expect((await facts()).whereType<EntryCorrected>(), isEmpty);
    });

    test('RN-208 e RN-120 · corrigir o valor de uma compra no vale acerta o '
        'saldo: 650 − 480, depois 650 − 400', () async {
      final open = await recorded(
        _draft(cents: 48000, category: 'groceries', method: _voucher),
      );
      expect((await book()).voucher.balance.cents, 17000);

      await ledger().correct(open.copyWith(amountCents: 40000));

      expect((await book()).voucher.balance.cents, 25000);
      expect(
        (await book()).spentIn(testToday.budgetMonth).mealVoucher.cents,
        40000,
      );
    });

    test(
      'RN-122 · correção que o vale não cobre é recusada, e nada muda',
      () async {
        final open = await recorded(
          _draft(cents: 60000, category: 'groceries', method: _voucher),
        );

        final result = await ledger().correct(
          open.copyWith(amountCents: 70000),
        );

        expect(result.failureOrNull, isA<VoucherBalanceExceeded>());
        expect((await book()).entries.single.amount.cents, 60000);
        expect((await book()).voucher.balance.cents, 5000);
      },
    );
  });

  group('cancelar (RN-208)', () {
    test('RN-208 · o lançamento cancelado sai de toda visão, o vale volta, e '
        'o fato original fica no registro', () async {
      final open = await recorded(
        _draft(cents: 48000, category: 'groceries', method: _voucher),
      );

      await ledger().cancel(open.correctionOf!, reason: 'Lancei duas vezes');
      final current = await book();

      expect(current.entries, isEmpty);
      expect(current.spentIn(testToday.budgetMonth), TenderAmounts.zero);
      expect(current.voucher.balance.cents, 65000);
      expect((await facts()).whereType<EntryRecorded>(), hasLength(1));
      expect(
        (await facts()).whereType<EntryCancelled>().single.reason,
        'Lancei duas vezes',
      );
    });

    test(
      'cancelar compra que já teve estorno não devolve o vale duas vezes',
      () async {
        final open = await recorded(
          _draft(cents: 48000, category: 'groceries', method: _voucher),
        );
        await ledger().reverse(
          entry: (await book()).entries.single,
          paymentMethodId: 'voucher',
          amount: const Money.fromCents(10000),
          occurredOn: testToday,
        );
        expect((await book()).voucher.balance.cents, 27000);

        await ledger().cancel(open.correctionOf!, reason: 'Lancei duas vezes');

        expect((await book()).voucher.balance.cents, 65000);
        expect((await book()).reversals, isEmpty);
      },
    );
  });

  group('estornar (RN-209 a RN-211)', () {
    Future<Result<Reversal>> reverse(int cents) async {
      final entry = (await book()).entries.single;
      return await ledger().reverse(
        entry: entry,
        paymentMethodId: 'pix',
        amount: Money.fromCents(cents),
        occurredOn: testToday,
      );
    }

    test('RN-209 · o estorno desconta no mês em que o dinheiro voltou, não no '
        'da compra: agosto não muda, setembro tem −120', () async {
      final august = LocalDate(2026, 8, 25);
      await ledger().record(_draft().copyWith(occurredOn: august));

      await reverse(12000);
      final current = await book();

      expect(current.spentIn(august.budgetMonth).cash.cents, 12000);
      expect(current.spentIn(testToday.budgetMonth).cash.cents, -12000);
    });

    test(
      'RN-210 · a soma dos estornos nunca passa do valor da compra',
      () async {
        await ledger().record(_draft());

        final first = await reverse(8000);
        final second = await reverse(5000);

        expect(first.isOk, isTrue);
        final failure = second.failureOrNull! as ReversalExceedsRemaining;
        expect(failure.remaining.cents, 4000);
        expect((await book()).reversals, hasLength(1));
      },
    );

    test(
      'RN-210 · corrigir não pode deixar a linha menor do que já voltou',
      () async {
        final open = await recorded(_draft());
        await reverse(8000);

        final result = await ledger().correct(open.copyWith(amountCents: 5000));

        expect(result.failureOrNull, isA<ReversalExceedsRemaining>());
        expect((await book()).entries.single.amount.cents, 12000);
      },
    );

    test('RN-211 · estorno de compra no vale devolve saldo ao vale', () async {
      await ledger().record(
        _draft(cents: 48000, category: 'groceries', method: _voucher),
      );

      await ledger().reverse(
        entry: (await book()).entries.single,
        paymentMethodId: 'voucher',
        amount: const Money.fromCents(10000),
        occurredOn: testToday,
      );

      expect((await book()).voucher.balance.cents, 27000);
      expect((await book()).spentIn(testToday.budgetMonth).cash, Money.zero);
    });
  });
}
