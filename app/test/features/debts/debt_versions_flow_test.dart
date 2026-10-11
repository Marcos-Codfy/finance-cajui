import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/debts/application/debts_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

Debt _bill(String id, int balance, DateTime at) => Debt.withBalance(
  id: id,
  creditor: id,
  kind: DebtKind.overdueBill,
  balance: Money.fromCents(balance),
  monthlyPayment: const Money.fromCents(10000),
  dueDay: 25,
  informedOn: testToday,
  definedAt: at,
).valueOrNull!;

void main() {
  late ProviderContainer container;

  Future<LedgerBook> book() => container.read(ledgerProvider.future);

  setUp(() async {
    container = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal()),
    );
    addTearDown(container.dispose);
    await book();
  });

  test('RN-1031 · atualizar o saldo mantém a dívida no lugar da fila de '
      'quitação', () async {
    final service = container.read(debtsServiceProvider);
    final luz = (await service.defineByBalance(
      creditor: 'Conta de luz',
      kind: DebtKind.overdueBill,
      balance: const Money.fromCents(50000),
      monthlyPayment: const Money.fromCents(10000),
      dueDay: 25,
    )).valueOrNull!;
    await service.defineByBalance(
      creditor: 'Carnê',
      kind: DebtKind.overdueBill,
      balance: const Money.fromCents(90000),
      monthlyPayment: const Money.fromCents(10000),
      dueDay: 25,
    );

    await service.updateBalance(luz, const Money.fromCents(30000));
    final open = BookFinances.of(await book()).openDebtsOn(testToday);

    expect([for (final debt in open) debt.creditor], ['Conta de luz', 'Carnê']);
  });

  test('ADR-024 · a versão mais velha, chegando depois de outro aparelho, '
      'não passa por cima da mais nova', () async {
    final ledger = container.read(ledgerProvider.notifier);
    final newer = _bill('luz', 70000, DateTime.utc(2026, 9, 20, 13));
    final older = _bill('luz', 80000, DateTime.utc(2026, 9, 20, 12));

    await ledger.append(DebtDefined(id: 'fato-novo', debt: newer));
    await ledger.append(DebtDefined(id: 'fato-velho', debt: older));

    expect(
      (await book()).debtOf('luz')!.informedBalance,
      const Money.fromCents(70000),
    );
  });

  test('ADR-024 · o carimbo da mudança nunca fica atrás do que o aparelho já '
      'tem, mesmo com o relógio atrasado', () async {
    final ledger = container.read(ledgerProvider.notifier);
    // A versão do outro celular, de uma hora no futuro deste relógio.
    final ahead = _bill('luz', 70000, DateTime.utc(2026, 9, 20, 13));
    await ledger.append(DebtDefined(id: 'fato-outro', debt: ahead));

    await container
        .read(debtsServiceProvider)
        .updateBalance(ahead, const Money.fromCents(20000));

    expect(
      (await book()).debtOf('luz')!.informedBalance,
      const Money.fromCents(20000),
    );
  });
}
