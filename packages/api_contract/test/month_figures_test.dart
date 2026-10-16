import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

MonthFigures _sample({Money? result}) => MonthFigures(
  period: '2026-10',
  hasPlan: true,
  cashIncome: Money.fromCents(300000),
  voucher: Money.fromCents(40000),
  fixedBills: Money.fromCents(150000),
  subscriptions: Money.fromCents(5000),
  dayToDay: Money.fromCents(160000),
  debtInstallments: Money.zero,
  tithe: Money.zero,
  totalOut: Money.fromCents(315000),
  voucherCovered: Money.fromCents(40000),
  outOfPocket: Money.fromCents(275000),
  result: result ?? Money.fromCents(25000),
  owed: Money.fromCents(80000),
);

void main() {
  group('os números da tela que vão junto da pergunta à Juju', () {
    test('ida e volta: o que o celular manda é o que o servidor lê', () {
      final read = MonthFigures.fromJson(_sample().toJson())!;

      expect(read.period, '2026-10');
      expect(read.hasPlan, isTrue);
      expect(read.cashIncome.cents, 300000);
      expect(read.voucher.cents, 40000);
      expect(read.outOfPocket.cents, 275000);
      expect(read.result.cents, 25000);
      expect(read.owed.cents, 80000);
      expect(read.toJson(), _sample().toJson());
    });

    test(
      'RN-111 · o vale vai separado e não entra no que entra em dinheiro',
      () {
        final json = _sample().toJson();

        expect(json['cashIncome'], 300000);
        expect(json['voucher'], 40000);
      },
    );

    test('mês que não fecha: a falta é o contrário da sobra', () {
      final short = _sample(result: Money.fromCents(-1500));

      expect(short.closes, isFalse);
      expect(short.shortfall.cents, 1500);
      expect(_sample().shortfall, Money.zero);
    });

    test('corpo malformado vira nulo, nunca erro', () {
      final json = _sample().toJson();

      expect(MonthFigures.fromJson(null), isNull);
      expect(MonthFigures.fromJson('sobra'), isNull);
      expect(MonthFigures.fromJson({...json, 'result': '250,00'}), isNull);
      expect(MonthFigures.fromJson({...json}..remove('owed')), isNull);
      expect(MonthFigures.fromJson({...json, 'period': 'x' * 11}), isNull);
      expect(MonthFigures.fromJson({...json, 'hasPlan': 'sim'}), isNull);
    });
  });
}
