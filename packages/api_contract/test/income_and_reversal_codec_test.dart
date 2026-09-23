import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const _groceries = Category(
  id: 'groceries',
  name: 'Mercado',
  block: Block.variable,
  groupId: 'food',
  // O vale só paga categoria elegível (RN-112), e este lançamento tem uma
  // linha no vale.
  voucherEligible: true,
);

final _today = LocalDate(2026, 9, 22);

/// Uma compra de R$ 86,00: R$ 30,00 no vale e R$ 56,00 no Pix.
Entry _entry() => Entry.create(
  id: 'e1',
  description: 'Mercado',
  amount: const Money.fromCents(8600),
  occurredOn: LocalDate(2026, 9, 12),
  category: _groceries,
  today: _today,
  paymentLines: const [
    PaymentLine(
      paymentMethodId: 'voucher',
      kind: PaymentMethodKind.mealVoucher,
      amount: Money.fromCents(3000),
    ),
    PaymentLine(
      paymentMethodId: 'pix',
      kind: PaymentMethodKind.pix,
      amount: Money.fromCents(5600),
    ),
  ],
).valueOrNull!;

Map<String, Object?> _receiptJson({int cents = 50000}) => {
  'id': 'r1',
  'sourceId': 'salario',
  'tender': 'mealVoucher',
  'amountCents': cents,
  'receivedOn': '2026-09-05',
};

Map<String, Object?> _reversalJson({int cents = 5600, String method = 'pix'}) =>
    {
      'id': 'rev1',
      'entryId': 'e1',
      'paymentMethodId': method,
      'amountCents': cents,
      'occurredOn': '2026-09-20',
    };

void main() {
  group('IncomeCodec', () {
    test('o recebimento vai e volta igual', () {
      final volta = IncomeCodec.decode(_receiptJson());

      expect(IncomeCodec.encode(volta), _receiptJson());
      expect(volta.tender, Tender.mealVoucher);
      expect(volta.amount, const Money.fromCents(50000));
      expect(volta.isOneOff, isFalse);
    });

    test('T-05 · campo a mais, valor não positivo e moeda inventada são '
        'recusados', () {
      expect(
        () => IncomeCodec.read({..._receiptJson(), 'bonus': 1}),
        throwsFormatException,
      );
      expect(
        () => IncomeCodec.read(_receiptJson(cents: 0)),
        throwsFormatException,
      );
      expect(
        () => IncomeCodec.read({..._receiptJson(), 'tender': 'bitcoin'}),
        throwsFormatException,
      );
    });

    test('entrada avulsa vem sem fonte, e isso é válido (RN-133)', () {
      final avulsa = IncomeCodec.read({
        'id': 'r2',
        'tender': 'cash',
        'amountCents': 12000,
        'receivedOn': '2026-09-10',
      });

      expect(avulsa.isOneOff, isTrue);
      expect(avulsa.sourceId, isNull);
    });

    test('RN-123 · o acerto de saldo do vale pode ser negativo', () {
      final acerto = IncomeCodec.readAdjustment(const {
        'id': 'a1',
        'adjustmentCents': -790,
        'on': '2026-09-20',
        'reason': 'o cartão mostrava outro saldo',
      });

      final volta = IncomeCodec.decodeAdjustment(acerto, orElse: 'outro');

      expect(volta.amount, const Money.fromCents(-790));
      expect(volta.id, 'a1');
      expect(volta.reason, 'o cartão mostrava outro saldo');
    });

    test('acerto de registro antigo, sem identificador, usa o do fato', () {
      final volta = IncomeCodec.decodeAdjustment(const {
        'adjustmentCents': 100,
        'on': '2026-09-20',
        'reason': 'acerto',
      }, orElse: 'voucher-adjust-1');

      expect(volta.id, 'voucher-adjust-1');
    });
  });

  group('ReversalCodec', () {
    test('RN-209 · o estorno vai e volta, sobre o lançamento original', () {
      final volta = ReversalCodec.decode(
        _reversalJson(),
        entry: _entry(),
      ).valueOrNull!;

      expect(ReversalCodec.encode(volta), _reversalJson());
      expect(volta.line.amount, const Money.fromCents(5600));
      expect(volta.occurredOn, LocalDate(2026, 9, 20));
    });

    test('RN-210 · estornar mais do que resta é falha, e não exceção', () {
      final recusa = ReversalCodec.decode(
        _reversalJson(cents: 9000),
        entry: _entry(),
      );

      expect(recusa.failureOrNull, isA<ReversalExceedsRemaining>());
    });

    test('RN-210 · o que já voltou conta: o segundo estorno vê o primeiro', () {
      final primeiro = ReversalCodec.decode(
        _reversalJson(cents: 4000),
        entry: _entry(),
      ).valueOrNull!;

      final segundo = ReversalCodec.decode(
        _reversalJson(cents: 2000),
        entry: _entry(),
        previous: [primeiro],
      );

      expect(segundo.failureOrNull, isA<ReversalExceedsRemaining>());
    });

    test('RN-211 · forma que o lançamento não usou tem zero a estornar', () {
      final recusa = ReversalCodec.decode(
        _reversalJson(method: 'boleto', cents: 100),
        entry: _entry(),
      );

      expect(
        (recusa.failureOrNull! as ReversalExceedsRemaining).remaining,
        Money.zero,
      );
    });

    test('T-05 · campo a mais e valor não positivo são recusados', () {
      expect(
        () => ReversalCodec.read({..._reversalJson(), 'extra': 1}),
        throwsFormatException,
      );
      expect(
        () => ReversalCodec.read(_reversalJson(cents: 0)),
        throwsFormatException,
      );
    });

    test('o que vem de fora volta conferido, e com a data normalizada', () {
      final lido = ReversalCodec.read(_reversalJson());

      expect(lido, _reversalJson());
    });
  });
}
