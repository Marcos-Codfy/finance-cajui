import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';

Money _brl(num reais) => Money.fromCents((reais * 100).round());

void main() {
  group('RN-758 · o recebimento que parece o salário', () {
    test('acha o salário pelo valor e pelo dia, e só se ainda não entrou no '
        'mês', () {
      final finances = household();
      final paid = household(
        receipts: [
          IncomeReceipt(
            id: 'r1',
            sourceId: 'salary-a',
            tender: Tender.cash,
            amount: _brl(1800),
            receivedOn: LocalDate(2026, 10, 5),
          ),
        ],
      );

      expect(
        finances.salaryLike(_brl(1750), LocalDate(2026, 10, 6))?.id,
        'salary-a',
      );
      expect(finances.salaryLike(_brl(150), LocalDate(2026, 10, 6)), isNull);
      expect(paid.salaryLike(_brl(1750), LocalDate(2026, 10, 6)), isNull);
    });
  });

  group('RN-1051 · salvar o plano', () {
    test(
      'o plano salvo ganha o carimbo e deixa as parcelas soltas do antigo',
      () {
        final saved = householdPlan()
            .copyWith(titheBasisPoints: 0)
            .savedAt(DateTime.utc(2026, 10, 11, 4));

        expect(saved.definedAt, DateTime.utc(2026, 10, 11, 4));
        expect(saved.titheBasisPoints, 0);
        expect(saved.legacyDebtInstallments, Money.zero);
        expect(saved.lines, hasLength(8));
      },
    );
  });

  group('RN-1004 · editar minhas contas', () {
    test('trocar, acrescentar e tirar linha e salário', () {
      final plan = householdPlan();
      final cheaper = BudgetLine.create(
        id: 'Aluguel',
        name: 'Aluguel',
        amount: _brl(900),
        group: LineGroup.fixedBill,
        categoryId: 'rent',
      ).valueOrNull!;

      final edited = plan
          .withLine(cheaper)
          .withoutLine('Música')
          .withSalary(salary('salary-c', 50000))
          .withoutSalary('salary-b');

      expect(edited.lines.first.amount, _brl(900));
      expect(edited.lines, hasLength(7));
      expect(edited.salaries.map((s) => s.id), ['salary-a', 'salary-c']);
    });
  });
}
