import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

final Debt _debt = Debt.create(
  id: 'debt-1',
  creditor: 'Banco do bairro',
  kind: DebtKind.loan,
  installmentAmount: const Money.fromCents(21200),
  totalInstallments: 12,
  paidInstallments: 5,
  dueDay: 10,
  firstMonth: const BudgetMonth(2026, 4),
).valueOrNull!;

Map<String, Object?> _fact(String type, Map<String, Object?> payload) => {
  'id': 'fato-1',
  'type': type,
  'payload': payload,
};

void main() {
  group('ADR-019 · os fatos que o servidor guarda sem fazer conta', () {
    test('a dívida vai e volta inteira, com o valor para quitar', () {
      final quoted = _debt.withPayoffQuote(
        PayoffQuote(
          amount: const Money.fromCents(130000),
          quotedOn: LocalDate(2026, 9, 18),
        ),
      );

      final fact = DeviceFact.read(
        _fact(DeviceFact.debtDefined, DebtCodec.encodeDebt(quoted)),
      );
      final back = DebtCodec.decodeDebt(fact.payload);

      expect(back.creditor, 'Banco do bairro');
      expect(back.paidInstallments, 5);
      expect(back.outstandingBalance, const Money.fromCents(148400));
      expect(back.payoffQuote?.amount, const Money.fromCents(130000));
    });

    test('a fatura paga, a parcela paga e o mês fechado também', () {
      final settled = DeviceFact.read(
        _fact(DeviceFact.statementSettled, {
          'id': 's1',
          'cardId': 'card-1',
          'dueMonth': '2026-10',
          'amountCents': 80000,
          'paidOn': '2026-10-05',
        }),
      );
      final paid = DeviceFact.read(
        _fact(DeviceFact.debtInstallmentPaid, {
          'debtId': 'debt-1',
          'entryId': 'e9',
        }),
      );
      final closed = DeviceFact.read(
        _fact(DeviceFact.monthClosed, {
          'month': '2026-08',
          'revision': 0,
          'cashResultCents': -14200,
          'closedOn': '2026-09-02',
        }),
      );

      expect(CardCodec.decodeSettlement(settled.payload).amount.cents, 80000);
      expect(DebtCodec.decodePayment(paid.payload).entryId, 'e9');
      expect(MonthCloseCodec.decode(closed.payload).cashResult.cents, -14200);
    });

    test('T-05 · guardar sem interpretar não é guardar sem conferir: o que o '
        'codec do tipo não aceita é recusado', () {
      final semParcela = {...DebtCodec.encodeDebt(_debt)}
        ..remove('installmentCents');
      final pagasDemais = {
        ...DebtCodec.encodeDebt(_debt),
        'paidInstallments': 99,
      };

      for (final payload in [semParcela, pagasDemais]) {
        expect(
          () => DeviceFact.read(_fact(DeviceFact.debtDefined, payload)),
          throwsFormatException,
        );
      }
    });

    test('T-05 · o que não tem cabimento não é guardado: mês 13, valor pago '
        'negativo, revisão negativa, texto sem fim', () {
      final recusados = [
        _fact(DeviceFact.statementSettled, {
          'id': 's1',
          'cardId': 'card-1',
          'dueMonth': '2026-13',
          'amountCents': 80000,
          'paidOn': '2026-10-05',
        }),
        _fact(DeviceFact.statementSettled, {
          'id': 's1',
          'cardId': 'card-1',
          'dueMonth': '2026-10',
          'amountCents': -80000,
          'paidOn': '2026-10-05',
        }),
        _fact(DeviceFact.monthClosed, {
          'month': '2026-08',
          'revision': -7,
          'cashResultCents': 0,
          'closedOn': '2026-09-02',
        }),
        _fact(DeviceFact.debtDefined, {
          ...DebtCodec.encodeDebt(_debt),
          'creditor': 'x' * 60000,
        }),
      ];

      for (final fact in recusados) {
        expect(() => DeviceFact.read(fact), throwsFormatException);
      }
    });

    test('tipo fora dos quatro e campo a mais são recusados (E-REQ-01)', () {
      final outroTipo = _fact('entry.created', const {});
      final campoAMais = {
        ..._fact(DeviceFact.debtInstallmentPaid, {
          'debtId': 'debt-1',
          'entryId': 'e9',
        }),
        'dono': 'alguém',
      };

      expect(() => DeviceFact.read(outroTipo), throwsFormatException);
      expect(() => DeviceFact.read(campoAMais), throwsFormatException);
    });

    test('o conteúdo volta normalizado: o que o codec não conhece não é '
        'guardado', () {
      final fact = DeviceFact.read(
        _fact(DeviceFact.debtInstallmentPaid, {
          'debtId': 'debt-1',
          'entryId': 'e9',
          'contrato': '123456',
        }),
      );

      expect(fact.payload.keys, unorderedEquals(['debtId', 'entryId']));
    });
  });
}
