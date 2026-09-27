import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/sync_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// Um celular: livro próprio, na memória, ligado ao mesmo servidor de
/// mentira que o outro. [today] muda entre os dois de propósito: é o que
/// dá carimbos diferentes ao plano de cada um.
ProviderContainer _phone(FakeExchange server, {LocalDate? today}) {
  final scope = ProviderContainer(
    overrides: testOverrides(
      journal: MemoryLedgerJournal(),
      uplink: server,
      downlink: server,
      today: today,
    ),
  );
  addTearDown(scope.dispose);
  return scope;
}

Future<LedgerBook> _sync(ProviderContainer phone) async {
  final book = await phone.read(ledgerProvider.future);
  await phone.read(ledgerSyncProvider).run(book);
  return await phone.read(ledgerProvider.future);
}

EntryDraft _draft(LedgerBook book, {int cents = 8600, String what = 'Feira'}) =>
    EntryDraft(
      amountCents: cents,
      description: what,
      category: book.categoryOf('groceries'),
      method: book.methodOf('pix'),
      occurredOn: testToday,
    );

/// O rascunho que corrige o único lançamento de [book].
EntryDraft _correcting(LedgerBook book, {int? cents, String? method}) {
  final entry = book.entries.single;
  return EntryDraft.correcting(
    entry,
    category: book.categoryOf(entry.categoryId),
    methodOf: book.methodOf,
  ).copyWith(
    amountCents: cents,
    method: method == null ? null : book.methodOf(method),
  );
}

void main() {
  late FakeExchange server;
  late ProviderContainer a;
  late ProviderContainer b;

  setUp(() {
    server = FakeExchange();
    a = _phone(server);
    b = _phone(server, today: testToday.addDays(1));
  });

  group('BL-062 · dois celulares, um livro', () {
    test('o que um lança, o outro passa a ter', () async {
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);

      final bookB = await _sync(b);

      expect(bookB.entries, hasLength(1));
      expect(bookB.entries.single.description, 'Feira');
      expect(bookB.entries.single.amount, const Money.fromCents(8600));
    });

    test('sincronizar de novo não duplica nada, em nenhum dos dois', () async {
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);
      await _sync(b);

      final again = await _sync(b);
      final backOnA = await _sync(a);

      expect(again.entries, hasLength(1));
      expect(backOnA.entries, hasLength(1));
      expect(server.entries, hasLength(1));
    });

    test('a correção feita num aparelho chega ao outro', () async {
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);
      final bookB = await _sync(b);

      final corrected = EntryDraft.correcting(
        bookB.entries.single,
        category: bookB.categoryOf('groceries'),
        methodOf: bookB.methodOf,
      ).copyWith(amountCents: 9900, description: 'Feira grande');
      await b.read(ledgerProvider.notifier).correct(corrected);
      await _sync(b);

      final backOnA = await _sync(a);

      expect(backOnA.entries.single.amount, const Money.fromCents(9900));
      expect(backOnA.entries.single.description, 'Feira grande');
    });

    test('corrigir só a forma de pagamento também chega ao outro: é o que '
        'diz se saiu do vale ou do dinheiro (RN-111)', () async {
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);
      final bookB = await _sync(b);

      await b
          .read(ledgerProvider.notifier)
          .correct(_correcting(bookB, method: 'debit'));
      await _sync(b);
      final backOnA = await _sync(a);

      expect(
        backOnA.entries.single.paymentLines.single.paymentMethodId,
        'debit',
      );
    });

    test('entre duas correções, vence a mais nova pelo carimbo — não a que '
        'subiu por último', () async {
      // A corrige no dia 20 e B no dia 21. B sobe primeiro; quando A sobe,
      // a versão dele é mais velha e não passa por cima: desce a de B.
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);
      final bookB = await _sync(b);

      await a
          .read(ledgerProvider.notifier)
          .correct(
            _correcting(await a.read(ledgerProvider.future), cents: 7000),
          );
      await b
          .read(ledgerProvider.notifier)
          .correct(_correcting(bookB, cents: 9900));
      await _sync(b);
      final onA = await _sync(a);
      final onB = await _sync(b);

      expect(onA.entries.single.amount, const Money.fromCents(9900));
      expect(onB.entries.single.amount, const Money.fromCents(9900));
      expect(server.entries.values.single.amountCents, 9900);
    });

    test('o cancelamento feito num aparelho cancela no outro — e o outro '
        'não manda o lançamento de volta', () async {
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);
      final bookB = await _sync(b);
      expect(bookB.entries, hasLength(1), reason: 'B recebeu');

      await a
          .read(ledgerProvider.notifier)
          .cancel(
            bookA.entries.isEmpty
                ? (await a.read(ledgerProvider.future)).entries.single.id
                : bookA.entries.single.id,
            reason: 'lancei errado',
          );
      await _sync(a);
      final afterOnB = await _sync(b);

      expect(afterOnB.entries, isEmpty, reason: 'B cancelou também');
      expect(server.entries, isEmpty, reason: 'B não ressuscitou no servidor');
    });

    test(
      'o plano mais novo vence, e não o que sincronizou por último',
      () async {
        // A edita o plano no dia 20; B edita no dia 21. A sincroniza depois de
        // B — e mesmo assim o de B, mais novo, é o que fica nos dois.
        await a
            .read(ledgerProvider.notifier)
            .definePlan(
              samplePlan.withMoney(cashIncome: const Money.fromCents(100000)),
            );
        await b
            .read(ledgerProvider.notifier)
            .definePlan(
              samplePlan.withMoney(cashIncome: const Money.fromCents(200000)),
            );
        await _sync(b);
        final onA = await _sync(a);
        final onB = await _sync(b);

        expect(onA.setup.cashIncome, const Money.fromCents(200000));
        expect(onB.setup.cashIncome, const Money.fromCents(200000));
        expect(server.plan.cashIncome, const Money.fromCents(200000));
      },
    );

    test('duas sincronizações ao mesmo tempo não contam o lançamento em '
        'dobro', () async {
      final bookA = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(_draft(bookA));
      await _sync(a);

      // O mesmo livro velho nas duas — é o que acontece quando a subida
      // silenciosa e a pergunta ao assistente descem juntas.
      final stale = await b.read(ledgerProvider.future);
      final sync = b.read(ledgerSyncProvider);
      final outcomes = await Future.wait([sync.run(stale), sync.run(stale)]);
      final onB = await b.read(ledgerProvider.future);

      expect(onB.entries, hasLength(1));
      expect(outcomes.map((o) => o.received).reduce((x, y) => x + y), 1);
    });

    test(
      'corrigir o que o outro celular cancelou avisa, em vez de estourar',
      () async {
        final bookA = await a.read(ledgerProvider.future);
        await a.read(ledgerProvider.notifier).record(_draft(bookA));
        await _sync(a);
        final bookB = await _sync(b);
        final draft = _correcting(bookB, cents: 9900);

        await a
            .read(ledgerProvider.notifier)
            .cancel(
              (await a.read(ledgerProvider.future)).entries.single.id,
              reason: 'lancei errado',
            );
        await _sync(a);
        await _sync(b);
        final result = await b.read(ledgerProvider.notifier).correct(draft);

        expect(result.failureOrNull, isA<EntryNoLongerExists>());
      },
    );

    test('o cartão e a compra parcelada atravessam inteiros', () async {
      await a
          .read(ledgerProvider.notifier)
          .defineCard(id: 'card-1', name: 'Cartão', closingDay: 25, dueDay: 5);
      final bookA = await a.read(ledgerProvider.future);
      await a
          .read(ledgerProvider.notifier)
          .record(
            _draft(
              bookA,
              cents: 96000,
              what: 'Fogão',
            ).copyWith(method: bookA.methodOf('card-1'), installments: 6),
          );
      await _sync(a);

      final bookB = await _sync(b);

      expect(bookB.cards, hasLength(1));
      expect(bookB.entries.single.installmentPlan?.count, 6);
    });
  });
}
