import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

BudgetPlan _plan() => BudgetPlan(
  definedAt: DateTime.utc(2026, 10, 11, 3),
  salaries: const [
    IncomeSource(
      id: BudgetPlan.firstSalaryId,
      name: 'Pessoa A',
      tender: Tender.cash,
      expectedAmount: Money.fromCents(180000),
      expectedDay: 5,
    ),
  ],
  voucher: const Money.fromCents(50000),
  titheBasisPoints: 1000,
  lines: [
    BudgetLine.create(
      id: 'l1',
      name: 'Streaming',
      amount: const Money.fromCents(4000),
      group: LineGroup.subscription,
      categoryId: 'subscriptions',
      paymentMethodId: 'card-1',
      note: 'ver em qual cartão cai',
      dueDay: 12,
    ).valueOrNull!,
  ],
);

Map<String, Object?> _fact(String type, Map<String, Object?> payload) => {
  'id': 'fato-1',
  'type': type,
  'payload': payload,
};

void main() {
  group('ADR-023 · o plano da planilha viaja entre os aparelhos', () {
    test('vai e volta inteiro, pelo registro e pela rede', () {
      final encoded = BudgetPlanCodec.encode(_plan());

      for (final back in [
        BudgetPlanCodec.decode(encoded),
        BudgetPlanCodec.read(encoded),
      ]) {
        expect(back.definedAt, DateTime.utc(2026, 10, 11, 3));
        expect(
          back.salaries.single.expectedAmount,
          const Money.fromCents(180000),
        );
        expect(back.voucher, const Money.fromCents(50000));
        expect(back.titheBasisPoints, 1000);
        final line = back.lines.single;
        expect(line.group, LineGroup.subscription);
        expect(line.paymentMethodId, 'card-1');
        expect(line.note, 'ver em qual cartão cai');
        expect(line.dueDay, 12);
      }
    });

    test('RN-1003 · pela rede, parcela de dívida como linha é pedido '
        'malformado; assim como valor negativo e dízimo acima de 100%', () {
      Map<String, Object?> withLine(Map<String, Object?> change) {
        final encoded = BudgetPlanCodec.encode(_plan());
        final line = {
          ...(encoded['lines']! as List).single as Map<String, Object?>,
          ...change,
        };
        return {
          ...encoded,
          'lines': [line],
        };
      }

      expect(
        () => BudgetPlanCodec.read(withLine({'group': 'debtInstallment'})),
        throwsFormatException,
      );
      expect(
        () => BudgetPlanCodec.read(withLine({'amountCents': -1})),
        throwsFormatException,
      );
      expect(
        () => BudgetPlanCodec.read({
          ...BudgetPlanCodec.encode(_plan()),
          'titheBasisPoints': 10001,
        }),
        throwsFormatException,
      );
    });

    test('o registro tolera linha que não se lê, e o resto continua', () {
      final encoded = BudgetPlanCodec.encode(_plan());
      final back = BudgetPlanCodec.decode({
        ...encoded,
        'lines': [
          ...encoded['lines']! as List,
          {'id': 'x', 'group': 'inventado'},
        ],
      });

      expect(back.lines, hasLength(1));
    });

    test('o servidor aceita o plano e a ordem das dívidas como fatos', () {
      final plan = DeviceFact.read(
        _fact(DeviceFact.budgetDefined, BudgetPlanCodec.encode(_plan())),
      );
      final ordering = DeviceFact.read(
        _fact(
          DeviceFact.debtOrdered,
          DebtCodec.encodeOrdering((
            ids: ['atrasada', 'carne'],
            definedAt: DateTime.utc(2026, 10, 11),
          )),
        ),
      );

      expect(BudgetPlanCodec.decode(plan.payload).titheBasisPoints, 1000);
      expect(DebtCodec.decodeOrdering(ordering.payload).ids, [
        'atrasada',
        'carne',
      ]);
    });
  });

  group('RN-1030 · a dívida de saldo informado na ida e volta', () {
    test('saldo, dia informado e observação voltam; o tipo é atrasado', () {
      final debt = Debt.withBalance(
        id: 'atrasada',
        creditor: 'Banco de exemplo',
        kind: DebtKind.overdueBill,
        balance: const Money.fromCents(380000),
        monthlyPayment: Money.zero,
        dueDay: 5,
        informedOn: LocalDate(2026, 10, 11),
        note: 'negociar à vista',
      ).valueOrNull!;

      final back = DebtCodec.decodeDebt(DebtCodec.encodeDebt(debt));

      expect(back.informedBalance, const Money.fromCents(380000));
      expect(back.informedOn, LocalDate(2026, 10, 11));
      expect(back.note, 'negociar à vista');
      expect(back.type, DebtType.overdue);
    });
  });
}
