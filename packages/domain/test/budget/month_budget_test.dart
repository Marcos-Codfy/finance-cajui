import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';

Money _brl(num reais) => Money.fromCents((reais * 100).round());

void main() {
  group('RN-1010 a RN-1017 · o mês como na planilha', () {
    test(r'o exemplo da casa: entra R$ 3.300, sai do bolso R$ 2.380, sobram '
        r'R$ 920', () {
      final month = household().budgetFor(october);

      expect(month.cashIncome, _brl(3300));
      expect(month.fixedBills, _brl(1270));
      expect(month.subscriptions, _brl(60));
      expect(month.dayToDay, _brl(1100));
      expect(month.debtInstallments, _brl(120));
      expect(month.tithe, _brl(330));
      expect(month.totalOut, _brl(2880));
      expect(month.voucherCovered, _brl(500));
      expect(month.outOfPocket, _brl(2380));
      expect(month.result, _brl(920));
      expect(month.closes, isTrue);
      expect(month.shortfall, Money.zero);
      expect(month.spentPercent, 72);
    });

    test('RN-1014 · quando falta: o mês não fecha, e "já está gasto" passa '
        'de 100%', () {
      final month = household(plans: [householdPlan(firstSalary: 50000)])
          .budgetFor(october);

      expect(month.cashIncome, _brl(2000));
      expect(month.tithe, _brl(200));
      expect(month.outOfPocket, _brl(2250));
      expect(month.result, _brl(-250));
      expect(month.closes, isFalse);
      expect(month.shortfall, _brl(250));
      expect(month.spentPercent, 113);
    });

    test('RN-1017 · dízimo zero não sai nada', () {
      final month = household(plans: [householdPlan(titheBasisPoints: 0)])
          .budgetFor(october);

      expect(month.tithe, Money.zero);
      expect(month.result, _brl(1250));
    });

    test('RN-1012 · o vale cobre só até o que se gasta com comida', () {
      final month = MonthBudget.of(
        month: october,
        plan: BudgetPlan(voucher: _brl(900)),
        categories: householdCategories,
        spent: {'groceries': _brl(800), 'transport': _brl(100)},
        cashIncome: _brl(2000),
        voucher: _brl(900),
        debtInstallments: Money.zero,
      );

      expect(month.voucherCovered, _brl(800));
      expect(month.outOfPocket, _brl(100));
    });
  });

  group('RN-1005 · em cada categoria conta o maior: previsto ou gasto', () {
    test('mercado gasto acima do previsto conta pelo gasto; transporte abaixo '
        'conta pelo previsto', () {
      final month = household(
        entries: [
          spend(70000, category: 'groceries', on: LocalDate(2026, 10, 3)),
          spend(
            15000,
            id: 'e2',
            category: 'transport',
            on: LocalDate(2026, 10, 4),
          ),
        ],
      ).budgetFor(october);

      expect(month.dayToDay, _brl(1200));
      final transport = month.items.firstWhere(
        (item) => item.categoryId == 'transport',
      );
      expect(transport.counted, _brl(400));
      expect(transport.leftInPlan, _brl(250));
    });

    test('juros e tarifas lançados são gasto do dia a dia: parcela só vem da '
        'dívida', () {
      final month = household(
        entries: [
          spend(
            3000,
            category: 'interest-and-fees',
            on: LocalDate(2026, 10, 3),
          ),
        ],
      ).budgetFor(october);

      expect(month.dayToDay, _brl(1130));
      expect(month.debtInstallments, _brl(120));
    });

    test('pagamento ligado à dívida não conta duas vezes', () {
      final month = household(
        entries: [
          spend(
            12000,
            category: 'interest-and-fees',
            on: LocalDate(2026, 10, 10),
          ),
        ],
        excluded: {'e1'},
      ).budgetFor(october);

      expect(month.dayToDay, _brl(1100));
    });
  });

  group('RN-1006 · o que entra', () {
    test('salário recebido substitui o esperado; entrada avulsa soma', () {
      final month = household(
        receipts: [
          IncomeReceipt(
            id: 'r1',
            sourceId: 'salary-a',
            tender: Tender.cash,
            amount: _brl(1750),
            receivedOn: LocalDate(2026, 10, 5),
          ),
          IncomeReceipt(
            id: 'r2',
            tender: Tender.cash,
            amount: _brl(200),
            receivedOn: LocalDate(2026, 10, 12),
          ),
        ],
      ).budgetFor(october);

      expect(month.cashIncome, _brl(1750 + 1500 + 200));
    });

    test('vale creditado no mês vale no lugar do previsto', () {
      final finances = household(
        receipts: [
          IncomeReceipt(
            id: 'v1',
            tender: Tender.mealVoucher,
            amount: _brl(450),
            receivedOn: LocalDate(2026, 10, 1),
          ),
        ],
      );

      expect(finances.voucherIn(october), _brl(450));
      expect(finances.voucherIn(const BudgetMonth(2026, 11)), _brl(500));
    });
  });
}
