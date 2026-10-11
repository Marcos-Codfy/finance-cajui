import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// A conta atrasada de R$ 3.800, informada em 01/08 com R$ 200 por mês no
/// dia 10, e renegociada em 20/10 para R$ 1.000 com R$ 100 por mês.
Debt _overdue({
  required int balance,
  required int monthly,
  required LocalDate on,
  required DateTime at,
}) => Debt.withBalance(
  id: 'luz',
  creditor: 'Conta de luz',
  kind: DebtKind.overdueBill,
  balance: Money.fromCents(balance),
  monthlyPayment: Money.fromCents(monthly),
  dueDay: 10,
  informedOn: on,
  definedAt: at,
).valueOrNull!;

final Debt _before = _overdue(
  balance: 380000,
  monthly: 20000,
  on: LocalDate(2026, 8, 1),
  at: DateTime.utc(2026, 8, 1, 12),
);

final Debt _after = _overdue(
  balance: 100000,
  monthly: 10000,
  on: LocalDate(2026, 10, 20),
  at: DateTime.utc(2026, 10, 20, 12),
);

Finances _finances({List<Entry> entries = const []}) => Finances(
  categories: const {},
  plans: const [],
  entries: entries,
  debts: [_after],
  debtVersions: [_before, _after],
);

void main() {
  group('RN-1030 RN-1040 · negociar a dívida não reescreve o passado', () {
    test('setembro continua com a parcela e o saldo de setembro', () {
      final finances = _finances();

      expect(
        finances.budgetFor(const BudgetMonth(2026, 9)).debtInstallments.cents,
        20000,
      );
      // 3.800 menos as parcelas de 10/08 e 10/09.
      expect(
        finances.recordOf(const BudgetMonth(2026, 9)).stillOwed.cents,
        340000,
      );
    });

    test('a parcela de outubro, que venceu antes da negociação, continua no '
        'mês; a de novembro já é a nova', () {
      final finances = _finances();

      expect(
        finances.budgetFor(const BudgetMonth(2026, 10)).debtInstallments.cents,
        20000,
      );
      expect(
        finances.recordOf(const BudgetMonth(2026, 10)).stillOwed.cents,
        100000,
      );
      expect(
        finances.budgetFor(const BudgetMonth(2026, 11)).debtInstallments.cents,
        10000,
      );
    });

    test('antes do cadastro, a dívida não existia', () {
      expect(
        _finances().recordOf(const BudgetMonth(2026, 7)).stillOwed,
        Money.zero,
      );
    });
  });

  test('ADR-024 · entre dois celulares vale a versão mais nova pelo carimbo, '
      'e não a que chegou por último', () {
    final at9 = _overdue(
      balance: 100000,
      monthly: 10000,
      on: LocalDate(2026, 10, 11),
      at: DateTime.utc(2026, 10, 11, 12),
    );
    final at10 = _overdue(
      balance: 80000,
      monthly: 10000,
      on: LocalDate(2026, 10, 11),
      at: DateTime.utc(2026, 10, 11, 13),
    );

    // O de 10h chegou primeiro; o de 9h, depois.
    final current = DebtVersions.of([at10, at9]).current.single;

    expect(current.informedBalance, const Money.fromCents(80000));
  });

  test('RN-1032 · a compra parcelada de setembro não entra no que se devia '
      'em agosto', () {
    final tv = entry(
      id: 'tv',
      cents: 100000,
      lines: [credit(100000)],
      category: leisure,
      on: LocalDate(2026, 9, 25),
      plan: InstallmentPlan.forPurchase(
        card: card,
        purchasedOn: LocalDate(2026, 9, 25),
        principal: const Money.fromCents(100000),
        count: 10,
      ),
    );
    final finances = Finances(
      categories: const {},
      plans: const [],
      entries: [tv],
    );

    expect(finances.recordOf(const BudgetMonth(2026, 8)).stillOwed, Money.zero);
    expect(
      finances.recordOf(const BudgetMonth(2026, 9)).stillOwed.cents,
      100000,
    );
  });

  test('RN-1030 · na parcelada, o que já foi pago segue o calendário', () {
    final carne = Debt.create(
      id: 'carne',
      creditor: 'Carnê',
      kind: DebtKind.loan,
      installmentAmount: const Money.fromCents(10000),
      totalInstallments: 12,
      paidInstallments: 0,
      dueDay: 10,
      firstMonth: const BudgetMonth(2026, 6),
    ).valueOrNull!;

    final today = DebtCalendar.asOf(carne, LocalDate(2026, 9, 20));

    // Junho, julho, agosto e setembro já venceram.
    expect(today.paidInstallments, 4);
    expect(today.paidSoFar.cents, 40000);
  });

  test('RN-531 · a previsão da dívida de saldo começa no primeiro '
      'vencimento depois do dia informado', () {
    final debt = Debt.withBalance(
      id: 'd',
      creditor: 'Cartão atrasado',
      kind: DebtKind.cardRevolving,
      balance: const Money.fromCents(100000),
      monthlyPayment: const Money.fromCents(30000),
      dueDay: 10,
      informedOn: LocalDate(2026, 10, 11),
    ).valueOrNull!;

    // 10/11, 10/12, 10/01 e 10/02: o saldo só zera em fevereiro.
    expect(debt.payoffForecast, const BudgetMonth(2027, 2));
  });

  test('RN-1040 · o plano salvo às 22h do dia 31 vale para o mês dele', () {
    final before = BudgetPlan(
      salaries: const [
        IncomeSource(
          id: 'ana',
          name: 'Ana',
          tender: Tender.cash,
          expectedAmount: Money.fromCents(180000),
          expectedDay: 5,
        ),
      ],
      definedAt: DateTime.utc(2026, 10),
    );
    // 31/10 às 22h em Brasília é 01/11 à 01h em UTC.
    final late = before
        .copyWith(
          salaries: const [
            IncomeSource(
              id: 'ana',
              name: 'Ana',
              tender: Tender.cash,
              expectedAmount: Money.fromCents(300000),
              expectedDay: 5,
            ),
          ],
        )
        .savedAt(DateTime.utc(2026, 11, 1, 1));
    final finances = Finances(categories: const {}, plans: [before, late]);

    expect(finances.cashIncomeIn(const BudgetMonth(2026, 10)).cents, 300000);
  });
}
