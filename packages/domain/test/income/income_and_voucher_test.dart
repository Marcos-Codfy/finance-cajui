import 'package:domain/domain.dart';
import 'package:test/test.dart';

const _september = BudgetMonth(2026, 9);
const _salary = IncomeSource(
  id: 'salary',
  name: 'Salário',
  tender: Tender.cash,
  expectedAmount: Money.fromCents(240000),
  expectedDay: 5,
);
const _second = IncomeSource(
  id: 'second',
  name: 'Segunda renda',
  tender: Tender.cash,
  expectedAmount: Money.fromCents(80000),
  expectedDay: 20,
);
const _voucher = IncomeSource(
  id: 'voucher',
  name: 'Vale',
  tender: Tender.mealVoucher,
  expectedAmount: Money.fromCents(65000),
  expectedDay: 1,
);
const List<IncomeSource> _sources = [_salary, _second, _voucher];

IncomeReceipt _receipt(String? source, int cents, LocalDate day) =>
    IncomeReceipt(
      id: 'r-$cents',
      sourceId: source,
      tender: Tender.cash,
      amount: Money.fromCents(cents),
      receivedOn: day,
    );

void main() {
  group('VoucherAccount', () {
    test('RN-120 saldo = anterior + créditos − compras + estornos', () {
      final account = VoucherAccount(balance: const Money.fromCents(5000))
          .credit(const Money.fromCents(60000))
          .pay(const Money.fromCents(48000))
          .valueOrNull!
          .reverse(const Money.fromCents(1000));

      expect(account.balance, const Money.fromCents(18000));
    });

    test('RN-122 pagamento maior que o saldo é recusado, com a parte que '
        'falta cobrir', () {
      final account = VoucherAccount(balance: const Money.fromCents(3000));

      final failure = account.pay(const Money.fromCents(8600)).failureOrNull;

      expect(failure, isA<VoucherBalanceExceeded>());
      expect(
        (failure! as VoucherBalanceExceeded).uncovered,
        const Money.fromCents(5600),
      );
      expect(
        account.coverableFor(const Money.fromCents(8600)),
        const Money.fromCents(3000),
      );
    });

    test('RN-122 pagar exatamente o saldo zera o vale, sem ficar negativo', () {
      final account = VoucherAccount(balance: const Money.fromCents(3000));

      expect(
        account.pay(const Money.fromCents(3000)).valueOrNull!.balance,
        Money.zero,
      );
    });

    test('RN-123 o ajuste é a diferença entre o saldo real e o calculado', () {
      final account = VoucherAccount(balance: const Money.fromCents(17000));

      final adjustment = account.adjustmentTo(const Money.fromCents(16210));

      expect(adjustment, const Money.fromCents(-790));
      expect(account.adjust(adjustment).balance, const Money.fromCents(16210));
    });
  });

  group('MonthIncome', () {
    test('RN-130 e RN-111 o plano usa o esperado, separado por moeda', () {
      final income = MonthIncome.of(
        _september,
        sources: _sources,
        receipts: const [],
      );

      expect(income.amounts.cash, const Money.fromCents(320000));
      expect(income.amounts.mealVoucher, const Money.fromCents(65000));
    });

    test('RN-131 o recebido substitui o esperado só naquele mês', () {
      final receipts = [_receipt('salary', 231000, LocalDate(2026, 9, 5))];

      final september = MonthIncome.of(
        _september,
        sources: _sources,
        receipts: receipts,
      );
      final october = MonthIncome.of(
        _september.next,
        sources: _sources,
        receipts: receipts,
      );

      expect(september.amounts.cash, const Money.fromCents(311000));
      expect(october.amounts.cash, const Money.fromCents(320000));
    });

    test('RN-133 entrada avulsa conta no mês e não se projeta', () {
      final receipts = [_receipt(null, 15000, LocalDate(2026, 9, 18))];

      final september = MonthIncome.of(
        _september,
        sources: _sources,
        receipts: receipts,
      );
      final october = MonthIncome.of(
        _september.next,
        sources: _sources,
        receipts: receipts,
      );

      expect(september.amounts.cash, const Money.fromCents(335000));
      expect(october.amounts.cash, const Money.fromCents(320000));
    });

    test('RN-134 fonte desativada deixa de contar a partir do mês dado', () {
      const ending = IncomeSource(
        id: 'second',
        name: 'Segunda renda',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(80000),
        expectedDay: 20,
        inactiveFrom: BudgetMonth(2026, 11),
      );
      MonthIncome at(BudgetMonth month) => MonthIncome.of(
        month,
        sources: const [_salary, ending],
        receipts: const [],
      );

      expect(
        at(const BudgetMonth(2026, 10)).amounts.cash,
        const Money.fromCents(320000),
      );
      expect(
        at(const BudgetMonth(2026, 11)).amounts.cash,
        const Money.fromCents(240000),
      );
    });

    test('RN-135 mês sem renda em dinheiro marca os indicadores como '
        'indefinidos', () {
      final income = MonthIncome.of(
        _september,
        sources: const [_voucher],
        receipts: const [],
      );

      expect(income.hasCashIncome, isFalse);
      expect(income.amounts.mealVoucher, const Money.fromCents(65000));
    });
  });
}
