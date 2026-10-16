import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// O cartão atravessa o contrato porque o **servidor** precisa dele: sem o
/// cartão, ele não tem de onde recalcular as parcelas, e recusa toda compra
/// parcelada.
void main() {
  final card = CreditCard.create(
    id: 'card-1',
    name: 'Cartão da casa',
    closingDay: 25,
    dueDay: 5,
    creditLimit: const Money.fromCents(500000),
  ).valueOrNull!;

  group('CardCodec · cartão', () {
    test('o que vai para o registro volta o mesmo cartão', () {
      final volta = CardCodec.decodeCard(CardCodec.encodeCard(card));

      expect(volta.id, card.id);
      expect(volta.name, card.name);
      expect(volta.closingDay, 25);
      expect(volta.dueDay, 5);
      expect(volta.creditLimit, const Money.fromCents(500000));
    });

    test('RNF-SEC · número de cartão não existe no Cajui, nem aqui', () {
      final gravado = CardCodec.encodeCard(card);

      expect(gravado.keys, {
        'id',
        'name',
        'closingDay',
        'dueDay',
        'creditLimitCents',
      });
    });

    test('cartão sem limite informado volta sem limite', () {
      final semLimite = CreditCard.create(
        id: 'card-2',
        name: 'Cartão da loja',
        closingDay: 1,
        dueDay: 10,
      ).valueOrNull!;

      final volta = CardCodec.decodeCard(CardCodec.encodeCard(semLimite));

      expect(volta.creditLimit, isNull);
    });
  });

  group('CardCodec · pagamento de fatura', () {
    test('o que vai para o registro volta o mesmo pagamento (RN-340)', () {
      final settlement = Settlement(
        id: 'pay-1',
        cardId: 'card-1',
        dueMonth: const BudgetMonth(2026, 10),
        amount: const Money.fromCents(123456),
        paidOn: LocalDate(2026, 10, 5),
      );

      final volta = CardCodec.decodeSettlement(
        CardCodec.encodeSettlement(settlement),
      );

      expect(volta.id, 'pay-1');
      expect(volta.cardId, 'card-1');
      expect(volta.dueMonth, const BudgetMonth(2026, 10));
      expect(volta.amount, const Money.fromCents(123456));
      expect('${volta.paidOn}', '2026-10-05');
    });

    test('o mês da fatura viaja como AAAA-MM, e volta igual', () {
      final janeiro = Settlement(
        id: 'pay-2',
        cardId: 'card-1',
        dueMonth: const BudgetMonth(2027, 1),
        amount: Money.zero,
        paidOn: LocalDate(2027, 1, 5),
      );

      final gravado = CardCodec.encodeSettlement(janeiro);

      expect(gravado['dueMonth'], '2027-01');
      expect(CardCodec.decodeSettlement(gravado).dueMonth, janeiro.dueMonth);
    });
  });

  test('a cor do cartão vai e volta, e o cartão sem cor viaja como antes', () {
    final painted = CreditCard.create(
      id: 'card-1',
      name: 'Cartão Ipê',
      closingDay: 3,
      dueDay: 10,
      skin: 'ipe-roxo',
    ).valueOrNull!;
    final plain = CreditCard.create(
      id: 'card-2',
      name: 'Cartão',
      closingDay: 3,
      dueDay: 10,
    ).valueOrNull!;

    expect(
      CardCodec.decodeCard(CardCodec.encodeCard(painted)).skin,
      'ipe-roxo',
    );
    expect(CardCodec.encodeCard(plain).containsKey('skin'), isFalse);
    expect(CardCodec.decodeCard(CardCodec.encodeCard(plain)).skin, isNull);
  });
}
