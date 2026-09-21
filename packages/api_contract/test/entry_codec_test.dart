import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const _groceries = Category(
  id: 'groceries',
  name: 'Mercado',
  block: Block.variable,
  groupId: 'food',
  voucherEligible: true,
);

final _today = LocalDate(2026, 9, 20);

Entry _split() => Entry.create(
  id: 'e1',
  description: 'Mercado Boa Compra',
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

void main() {
  group('EntryCodec', () {
    test('o que vai para o pedido volta o mesmo lançamento', () {
      final request = EntryCodec.fromEntry(_split());
      final back = EntryCodec.toEntry(
        CreateEntryRequest.fromJson(request.toJson()),
        category: _groceries,
        today: _today,
      ).valueOrNull!;

      expect(back.id, 'e1');
      expect(back.amount, const Money.fromCents(8600));
      expect(back.occurredOn, LocalDate(2026, 9, 12));
      expect(back.paidByTender.mealVoucher, const Money.fromCents(3000));
      expect(back.paidByTender.cash, const Money.fromCents(5600));
    });

    test('RN-206 · regra recusada volta como falha, não como exceção', () {
      final request = EntryCodec.fromEntry(_split());

      final result = EntryCodec.toEntry(
        request,
        category: _groceries,
        today: LocalDate(2026, 9, 11),
      );

      expect(result.failureOrNull, isA<PurchaseDateInFuture>());
    });

    test('RN-311 · compra parcelada viaja só com o número de parcelas, e as '
        'parcelas são recalculadas a partir do cartão', () {
      final card = CreditCard.create(
        id: 'card-1',
        name: 'Cartão',
        closingDay: 25,
        dueDay: 5,
      ).valueOrNull!;
      final stove = Entry.create(
        id: 'stove',
        description: 'Fogão',
        amount: const Money.fromCents(96000),
        occurredOn: LocalDate(2026, 9, 19),
        category: _groceries,
        today: _today,
        paymentLines: const [
          PaymentLine(
            paymentMethodId: 'card-1',
            kind: PaymentMethodKind.creditCard,
            amount: Money.fromCents(96000),
          ),
        ],
        installmentPlan: InstallmentPlan.forPurchase(
          card: card,
          purchasedOn: LocalDate(2026, 9, 19),
          principal: const Money.fromCents(96000),
          count: 6,
        ),
      ).valueOrNull!;

      final json = EntryCodec.fromEntry(stove).toJson();
      final back = EntryCodec.toEntry(
        CreateEntryRequest.fromJson(json),
        category: _groceries,
        today: _today,
        cardOf: (id) => id == 'card-1' ? card : null,
      ).valueOrNull!;

      expect(json['installments'], 6);
      expect(json.toString(), isNot(contains('16000')));
      expect(back.installmentPlan!.count, 6);
      expect(
        back.installmentPlan!.installments.first.dueMonth,
        const BudgetMonth(2026, 10),
      );
      expect(back.installmentPlan!.installments.first.amount.cents, 16000);
    });

    test('pedido à vista continua sem o campo de parcelas', () {
      expect(
        EntryCodec.fromEntry(_split()).toJson().containsKey('installments'),
        isFalse,
      );
    });

    test('parcelamento sem cartão conhecido, ou com parcelas demais, é '
        'pedido malformado', () {
      CreateEntryRequest parceled(int count) => CreateEntryRequest.fromJson({
        ...EntryCodec.fromEntry(_split()).toJson(),
        'installments': count,
      });

      expect(
        () => EntryCodec.toEntry(
          parceled(3),
          category: _groceries,
          today: _today,
        ),
        throwsFormatException,
      );
      expect(
        () => EntryCodec.toEntry(
          parceled(EntryCodec.maxInstallments + 1),
          category: _groceries,
          today: _today,
        ),
        throwsFormatException,
      );
    });

    test('data que não existe e tipo desconhecido são pedido malformado', () {
      expect(() => EntryCodec.parseDate('2026-02-30'), throwsFormatException);
      expect(() => EntryCodec.parseDate('12/09/2026'), throwsFormatException);
      expect(
        () => EntryCodec.named(PaymentMethodKind.values, 'cheque'),
        throwsFormatException,
      );
    });
  });
}
