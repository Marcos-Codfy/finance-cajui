import 'package:cajui/src/features/ledger/application/frequent_spends.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/household_book.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Três mercados de R$ 150,00 em setembro, inventados: o normal da
/// categoria é R$ 150,00.
MemoryLedgerJournal _book() => MemoryLedgerJournal([
  for (final (i, day) in [2, 9, 16].indexed)
    recordedEntry(
      id: 'market-$i',
      cents: 15000,
      on: LocalDate(2026, 9, day),
      description: 'Mercado Boa Compra',
      categoryId: 'groceries',
    ),
]);

void main() {
  late ProviderContainer container;

  EntryFormViewModel form() => container.read(entryFormProvider.notifier);
  EntryFormState state() => container.read(entryFormProvider);

  setUp(() async {
    container = ProviderContainer(overrides: testOverrides(journal: _book()));
    addTearDown(container.dispose);
    container
      ..listen(entryFormProvider, (_, _) {})
      ..listen(frequentSpendsProvider, (_, _) {});
    await container.read(ledgerProvider.future);
  });

  /// Repete o mercado de sempre e troca o valor por [cents].
  Future<void> marketOf(int cents) async {
    final book = await container.read(ledgerProvider.future);
    final spend = container.read(frequentSpendsProvider).first;
    form().edit((d) => FrequentSpends.repeat(d, spend, book));
    form().edit((d) => d.copyWith(amountCents: cents));
  }

  test('o gasto de sempre preenche descrição, valor, categoria e forma de '
      'pagamento, e a data continua a de hoje', () async {
    final book = await container.read(ledgerProvider.future);
    final spend = container.read(frequentSpendsProvider).single;

    form().edit((d) => FrequentSpends.repeat(d, spend, book));

    final draft = state().draft;
    expect(spend.count, 3);
    expect(draft.description, 'Mercado Boa Compra');
    expect(draft.amountCents, 15000);
    expect(draft.category?.id, 'groceries');
    expect(draft.method?.id, 'pix');
    expect(draft.occurredOn, testToday);
  });

  test('o zero a mais pergunta antes de gravar, com o normal da '
      'categoria, e "Corrigir o valor" volta a editar sem gravar', () async {
    await marketOf(150000);

    await form().submit();

    final asking = state() as EntryFormConfirming;
    expect(asking.typical, const Money.fromCents(15000));
    form().reviewAmount();
    expect(state(), isA<EntryFormEditing>());
    final book = await container.read(ledgerProvider.future);
    expect(book.entries, hasLength(3));
  });

  test('"Está certo, salvar" grava o valor grande', () async {
    await marketOf(150000);
    await form().submit();

    await form().submit(confirmed: true);

    expect(state(), isA<EntryFormSaved>());
  });

  test('valor dentro do normal grava sem pergunta', () async {
    await marketOf(16000);

    await form().submit();

    expect(state(), isA<EntryFormSaved>());
  });
}
