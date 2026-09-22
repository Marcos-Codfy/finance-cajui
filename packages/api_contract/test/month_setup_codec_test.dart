import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Um plano com uma conta fixa e duas faixas, uma delas paga pelo vale.
final MonthSetup _plan = MonthSetup(
  cashIncome: const Money.fromCents(320000),
  debtInstallments: const Money.fromCents(45000),
  fixedExpenses: const [
    FixedExpense(
      id: 'rent',
      name: 'Aluguel',
      amount: Money.fromCents(120000),
      dueDay: 5,
      categoryId: 'housing',
      paymentMethodId: 'pix',
    ),
  ],
  variableBudgets: [
    VariableBudget(
      categoryId: 'groceries',
      range: AmountRange.create(
        min: const Money.fromCents(40000),
        max: const Money.fromCents(60000),
      ).valueOrNull!,
      voucherEligible: true,
    ),
  ],
);

Map<String, Object?> _body({
  Object? fixed,
  Object? variables,
  int cashIncomeCents = 320000,
}) => {
  'cashIncomeCents': cashIncomeCents,
  'debtInstallmentsCents': 45000,
  'fixed': fixed ?? const <Object?>[],
  'variables': variables ?? const <Object?>[],
};

void main() {
  group('o plano do mês na ida e na volta', () {
    test('o que é gravado é lido igual', () {
      final voltou = MonthSetupCodec.decode(MonthSetupCodec.encode(_plan));

      expect(voltou.cashIncome, _plan.cashIncome);
      expect(voltou.debtInstallments, _plan.debtInstallments);
      expect(voltou.fixedExpenses.single.name, 'Aluguel');
      expect(
        voltou.variableBudgets.single.range.max,
        const Money.fromCents(60000),
      );
      expect(voltou.variableBudgets.single.voucherEligible, isTrue);
    });

    test('o que vem pela rede também, campo a campo', () {
      final voltou = MonthSetupCodec.read(MonthSetupCodec.encode(_plan));

      expect(voltou.cashIncome, _plan.cashIncome);
      expect(voltou.fixedExpenses.single.dueDay, 5);
      expect(voltou.variableBudgets.single.categoryId, 'groceries');
    });

    test('quem ainda não cadastrou nada tem plano válido e vazio', () {
      final vazio = MonthSetupCodec.read({
        'cashIncomeCents': 0,
        'debtInstallmentsCents': 0,
      });

      expect(vazio.isEmpty, isTrue);
    });
  });

  group('T-05 o plano que vem de fora é conferido campo a campo', () {
    test('campo a mais é recusado', () {
      expect(
        () => MonthSetupCodec.read({..._body(), 'saldoSecreto': 1}),
        throwsFormatException,
      );
    });

    test('campo obrigatório faltando é recusado', () {
      expect(
        () => MonthSetupCodec.read({'cashIncomeCents': 1000}),
        throwsFormatException,
      );
    });

    test('renda negativa é recusada: quantia não tem sinal', () {
      expect(
        () => MonthSetupCodec.read(_body(cashIncomeCents: -1)),
        throwsFormatException,
      );
    });

    test('vencimento fora do mês é recusado', () {
      expect(
        () => MonthSetupCodec.read(
          _body(
            fixed: [
              {
                'id': 'rent',
                'name': 'Aluguel',
                'amountCents': 120000,
                'dueDay': 32,
                'categoryId': 'housing',
                'paymentMethodId': 'pix',
              },
            ],
          ),
        ),
        throwsFormatException,
      );
    });

    test('faixa com mínimo maior que o máximo é recusada', () {
      expect(
        () => MonthSetupCodec.read(
          _body(
            variables: [
              {
                'categoryId': 'groceries',
                'minCents': 90000,
                'maxCents': 60000,
                'voucherEligible': false,
              },
            ],
          ),
        ),
        throwsFormatException,
      );
    });

    test('lista com itens demais é recusada', () {
      expect(
        () => MonthSetupCodec.read(
          _body(fixed: List.filled(51, const <String, Object?>{})),
        ),
        throwsFormatException,
      );
    });

    test('registro antigo e incompleto ainda abre: decode é tolerante', () {
      final velho = MonthSetupCodec.decode({'cashIncomeCents': 1000});

      expect(velho.cashIncome, const Money.fromCents(1000));
      expect(velho.fixedExpenses, isEmpty);
    });
  });
}
