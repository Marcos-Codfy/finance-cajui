import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/budget/application/month_closing.dart';
import 'package:cajui/src/features/debts/application/debts_service.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

const _august = BudgetMonth(2026, 8);
const _october = BudgetMonth(2026, 10);

void main() {
  late FakeExchange server;
  late ProviderContainer a;
  late ProviderContainer b;

  setUp(() {
    server = FakeExchange();
    a = TwoPhones.on(server);
    b = TwoPhones.on(server, today: testToday.addDays(1));
  });

  Future<Debt> loanOn(ProviderContainer phone) async {
    final result = await phone
        .read(debtsServiceProvider)
        .define(
          creditor: 'Banco do bairro',
          kind: DebtKind.loan,
          installmentAmount: const Money.fromCents(21200),
          totalInstallments: 12,
          paidInstallments: 5,
          dueDay: 10,
          firstMonth: const BudgetMonth(2026, 4),
        );
    return result.valueOrNull!;
  }

  Future<CreditCard> cardOn(ProviderContainer phone) async {
    final result = await phone
        .read(ledgerProvider.notifier)
        .defineCard(id: 'card-1', name: 'Cartão', closingDay: 25, dueDay: 5);
    return result.valueOrNull!;
  }

  group('ADR-019 · o que só o aparelho interpreta também atravessa', () {
    test('a dívida cadastrada num celular aparece no outro, com as parcelas '
        'já pagas', () async {
      await loanOn(a);
      await TwoPhones.sync(a);

      final onB = await TwoPhones.sync(b);

      expect(onB.debts.single.creditor, 'Banco do bairro');
      expect(onB.debts.single.paidInstallments, 5);
      expect(onB.debts.single.remainingInstallments, 7);
    });

    test('RN-520 · a parcela paga num celular conta no outro, uma vez '
        'só', () async {
      final debt = await loanOn(a);
      final book = await a.read(ledgerProvider.future);
      await a
          .read(debtsServiceProvider)
          .payInstallment(debt, method: book.methodOf('pix'), on: testToday);
      await TwoPhones.sync(a);

      await TwoPhones.sync(b);
      final onB = await TwoPhones.sync(b);

      expect(onB.debts.single.paidInstallments, 6);
      expect(onB.entries.single.amount, const Money.fromCents(21200));
      expect(onB.debtPayments.values.single, debt.id);
    });

    test('RN-340 · a fatura paga num celular aparece paga no outro', () async {
      final card = await cardOn(a);
      await a
          .read(ledgerProvider.notifier)
          .settleStatement(
            card: card,
            dueMonth: _october,
            amount: const Money.fromCents(80000),
          );
      await TwoPhones.sync(a);

      final onB = await TwoPhones.sync(b);

      expect(onB.settlements.single.dueMonth, _october);
      expect(onB.settlements.single.amount, const Money.fromCents(80000));
    });

    test(
      'RN-440 · o mês fechado num celular aparece fechado no outro',
      () async {
        await a.read(ledgerProvider.notifier).definePlan(samplePlan);
        final closed = await a.read(monthClosingProvider).close(_august);
        await TwoPhones.sync(a);

        final onB = await TwoPhones.sync(b);

        expect(closed.valueOrNull, isNotNull);
        expect(
          onB.closeOf(_august)?.cashResult,
          closed.valueOrNull!.cashResult,
        );
      },
    );

    test('RN-314 · os juros da compra parcelada atravessam (BL-063)', () async {
      await cardOn(a);
      final book = await a.read(ledgerProvider.future);
      await a
          .read(ledgerProvider.notifier)
          .record(
            EntryDraft(
              amountCents: 96000,
              description: 'Fogão',
              category: book.categoryOf('groceries'),
              method: book.methodOf('card-1'),
              occurredOn: testToday,
              installments: 6,
              installmentAmountCents: 18000,
            ),
          );
      await TwoPhones.sync(a);

      final onB = await TwoPhones.sync(b);
      final plan = onB.entries.single.installmentPlan!;

      expect(plan.count, 6);
      expect(plan.interestTotal, const Money.fromCents(12000));
    });

    test('sincronizar de novo não conta nada em dobro', () async {
      final debt = await loanOn(a);
      final book = await a.read(ledgerProvider.future);
      await a
          .read(debtsServiceProvider)
          .payInstallment(debt, method: book.methodOf('pix'), on: testToday);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      final onB = await TwoPhones.sync(b);
      final onA = await TwoPhones.sync(a);

      expect(onA.debts.single.paidInstallments, 6);
      expect(onB.debts.single.paidInstallments, 6);
      expect(onA.facts, hasLength(2));
      expect(onB.facts, hasLength(2));
    });
  });

  group('celular reinstalado', () {
    test('o primeiro envio traz tudo de volta: plano, renda, vale, cartão, '
        'lançamentos, dívida, fatura paga e fechamento', () async {
      await a.read(ledgerProvider.notifier).definePlan(samplePlan);
      await a
          .read(incomeServiceProvider)
          .receiveIncome(
            tender: Tender.mealVoucher,
            amount: const Money.fromCents(65000),
            receivedOn: testToday,
          );
      final card = await cardOn(a);
      final debt = await loanOn(a);
      final book = await a.read(ledgerProvider.future);
      await a.read(ledgerProvider.notifier).record(TwoPhones.draft(book));
      await a
          .read(debtsServiceProvider)
          .payInstallment(debt, method: book.methodOf('pix'), on: testToday);
      await a
          .read(ledgerProvider.notifier)
          .settleStatement(
            card: card,
            dueMonth: _october,
            amount: const Money.fromCents(80000),
          );
      await a.read(monthClosingProvider).close(_august);
      final before = await TwoPhones.sync(a);

      final reinstalled = TwoPhones.on(server);
      final after = await TwoPhones.sync(reinstalled);

      expect(after.setup.cashIncome, before.setup.cashIncome);
      expect(after.voucher, before.voucher);
      expect(after.cards.single.name, 'Cartão');
      expect(after.entries, hasLength(before.entries.length));
      expect(after.debts.single.paidInstallments, 6);
      expect(after.settlements, hasLength(1));
      expect(after.closeOf(_august), isNotNull);
    });
  });
}
