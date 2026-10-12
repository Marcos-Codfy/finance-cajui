import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/statements/application/statement_batch.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O salário da Ana, R$ 1.800,00 no dia 5, e mais nada.
final _plan = BudgetDefined(
  BudgetPlan(
    salaries: const [
      IncomeSource(
        id: 'ana',
        name: 'Ana',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(180000),
        expectedDay: 5,
      ),
    ],
    definedAt: DateTime.utc(2026, 9),
  ),
);

ResolvedLine _line(
  String description,
  int cents, {
  StatementLineKind kind = StatementLineKind.expense,
  PaymentMethodKind? paidWith,
}) => ResolvedLine(
  line: StatementLine(
    occurredOn: LocalDate(2026, 9, 5),
    description: description,
    amount: Money.fromCents(cents),
    kind: kind,
    categoryId: kind == StatementLineKind.expense ? 'groceries' : null,
    paymentKind: paidWith,
  ),
  merchantKey: MerchantBrand.keyOf(description),
);

/// Uma compra no vale, para que a "última forma usada" seja o vale.
Future<void> _spendVoucher(ProviderContainer phone) async {
  final book = await phone.read(ledgerProvider.future);
  final spent = await phone
      .read(ledgerProvider.notifier)
      .record(
        EntryDraft(
          amountCents: 3000,
          description: 'Feira',
          occurredOn: LocalDate(2026, 9, 4),
          category: book.categoriesById['groceries'],
          method: book.methods.firstWhere(
            (method) => method.kind == PaymentMethodKind.mealVoucher,
          ),
        ),
      );
  expect(spent.valueOrNull, isNotNull, reason: 'a feira saiu do vale');
}

void main() {
  late ProviderContainer phone;

  setUp(() async {
    phone = ProviderContainer(overrides: testOverrides());
    addTearDown(phone.dispose);
    final ledger = phone.read(ledgerProvider.notifier);
    for (final event in [...samplePlanEvents, _plan]) {
      await ledger.append(event);
    }
  });

  Future<StatementBatchOutcome> record(List<ResolvedLine> lines) => phone
      .read(statementBatchProvider)
      .record(lines, [for (var i = 0; i < lines.length; i++) i], launch: 'l1');

  test('RN-111 · a linha sem forma escrita sai da conta, nunca do vale, '
      'mesmo com o vale como última forma usada', () async {
    await _spendVoucher(phone);

    final outcome = await record([_line('Mercado Boa Vista', 8000)]);

    final book = await phone.read(ledgerProvider.future);
    final entry = book.entryOf(outcome.entries.single)!;
    expect(entry.paymentLines.single.kind, PaymentMethodKind.debit);
  });

  test('a compra no cartão sem cartão cadastrado sai da conta', () async {
    final outcome = await record([
      _line('Loja Estrela', 8990, paidWith: PaymentMethodKind.creditCard),
    ]);

    final book = await phone.read(ledgerProvider.future);
    final entry = book.entryOf(outcome.entries.single)!;
    expect(entry.paymentLines.single.kind, PaymentMethodKind.debit);
  });

  test(
    'RN-758 · a entrada do tamanho do salário entra como o salário',
    () async {
      final outcome = await record([
        _line('TED recebida', 180000, kind: StatementLineKind.income),
      ]);

      final book = await phone.read(ledgerProvider.future);
      final receipt = book.receipts.singleWhere(
        (receipt) => receipt.id == outcome.incomes.single,
      );
      expect(receipt.sourceId, 'ana');
      expect(receipt.amount, const Money.fromCents(180000));
    },
  );

  test('RN-1117 · o mesmo lote de novo não grava em dobro', () async {
    final lines = [_line('Mercado Boa Vista', 8000)];
    await record(lines);

    final again = await phone.read(statementBatchProvider).record(lines, [
      0,
    ], launch: 'l2');

    expect(again.entries, isEmpty);
    expect(again.alreadyThere, 1);
  });
}
