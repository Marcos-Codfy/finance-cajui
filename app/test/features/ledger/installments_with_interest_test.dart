import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

void main() {
  late ProviderContainer scope;

  LedgerController controller() => scope.read(ledgerProvider.notifier);

  setUp(() async {
    scope = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal()),
    );
    addTearDown(scope.dispose);
    await controller().defineCard(
      id: 'card-1',
      name: 'Cartão',
      closingDay: 25,
      dueDay: 5,
    );
  });

  /// R$ 960,00 em 6 vezes, com [each] de parcela.
  EntryDraft draftOf({int? each}) {
    final book = scope.read(ledgerProvider).value!;
    return EntryDraft(
      amountCents: 96000,
      description: 'Fogão',
      category: book.categoryOf('groceries'),
      method: book.methodOf('card-1'),
      occurredOn: testToday,
      installments: 6,
      installmentAmountCents: each,
    );
  }

  group('RN-314 · parcelamento com juros', () {
    test('sem valor de parcela, as parcelas são o total dividido e não há '
        'juros', () async {
      await controller().record(draftOf());
      final book = await scope.read(ledgerProvider.future);

      final plan = book.entries.single.installmentPlan!;
      expect(plan.installments.first.amount, const Money.fromCents(16000));
      expect(plan.interestTotal, Money.zero);
    });

    test('com a parcela informada, a diferença vira juros — e o valor da '
        'compra não muda', () async {
      await controller().record(draftOf(each: 18000));
      final book = await scope.read(ledgerProvider.future);

      final entry = book.entries.single;
      expect(entry.amount, const Money.fromCents(96000));
      expect(
        entry.installmentPlan!.interestTotal,
        const Money.fromCents(12000),
      );
      expect(
        entry.installmentPlan!.installments.first.amount,
        const Money.fromCents(18000),
      );
    });

    test('trocar o valor da compra apaga a parcela informada: juros de uma '
        'conta que não existe mais seria pior que nenhum', () {
      final comJuros = draftOf(each: 18000);

      final outroValor = comJuros.copyWith(amountCents: 50000);
      final outraParcela = comJuros.copyWith(installments: 10);

      expect(outroValor.installmentAmountCents, isNull);
      expect(outraParcela.installmentAmountCents, isNull);
      expect(comJuros.interestCents, 12000);
    });
  });
}
