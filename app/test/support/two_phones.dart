import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/sync_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_exchange.dart';
import 'memory_ledger_journal.dart';
import 'test_scope.dart';

/// Os dois celulares dos testes de sincronização (BL-062): cada um com o
/// livro próprio, na memória, ligado ao mesmo servidor de mentira.
abstract final class TwoPhones {
  static int _made = 0;

  /// Um celular sobre [server]. [today] muda entre os dois de propósito: é
  /// o que dá carimbos diferentes às edições de cada um. Cada celular gera
  /// identificadores próprios, como na vida real: com os dois contando do
  /// zero, o lançamento novo de um colidia com o que desceu do outro.
  static ProviderContainer on(FakeExchange server, {LocalDate? today}) {
    final scope = ProviderContainer(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(),
        uplink: server,
        downlink: server,
        today: today,
        idPrefix: 'celular${_made++}',
      ),
    );
    addTearDown(scope.dispose);
    return scope;
  }

  /// Sincroniza [phone] e devolve o livro como ficou.
  static Future<LedgerBook> sync(ProviderContainer phone) async {
    final book = await phone.read(ledgerProvider.future);
    await phone.read(ledgerSyncProvider).run(book);
    return await phone.read(ledgerProvider.future);
  }

  /// Uma compra de mercado, paga inteira por [method].
  static EntryDraft draft(
    LedgerBook book, {
    int cents = 8600,
    String what = 'Feira',
    String method = 'pix',
  }) => EntryDraft(
    amountCents: cents,
    description: what,
    category: book.categoryOf('groceries'),
    method: book.methodOf(method),
    occurredOn: testToday,
  );
}
