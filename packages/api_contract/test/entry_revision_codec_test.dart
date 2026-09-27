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
final _stamp = DateTime.utc(2026, 9, 21, 12, 30);

Entry _entry({DateTime? revisedAt}) => Entry.create(
  id: 'e1',
  description: 'Feira',
  amount: const Money.fromCents(8600),
  occurredOn: LocalDate(2026, 9, 12),
  category: _groceries,
  today: _today,
  paymentLines: const [
    PaymentLine(
      paymentMethodId: 'pix',
      kind: PaymentMethodKind.pix,
      amount: Money.fromCents(8600),
    ),
  ],
  revisedAt: revisedAt,
).valueOrNull!;

Entry _back(Map<String, Object?> json) => EntryCodec.toEntry(
  CreateEntryRequest.fromJson(json),
  category: _groceries,
  today: _today,
).valueOrNull!;

void main() {
  group('BL-062 · o carimbo da correção viaja com o lançamento', () {
    test('vai e volta o mesmo instante, em UTC', () {
      final json = EntryCodec.fromEntry(_entry(revisedAt: _stamp)).toJson();

      expect(json['revisedAt'], '2026-09-21T12:30:00.000Z');
      expect(_back(json).revisedAt, _stamp);
    });

    test('lançamento nunca corrigido não leva o campo: o pedido de antes '
        'continua igual', () {
      final json = EntryCodec.fromEntry(_entry()).toJson();

      expect(json.containsKey('revisedAt'), isFalse);
      expect(_back(json).revisedAt, isNull);
    });

    test('carimbo ilegível vale como nenhum, e o lançamento ainda abre', () {
      final json = {
        ...EntryCodec.fromEntry(_entry()).toJson(),
        'revisedAt': 'ontem de tarde',
      };

      expect(_back(json).revisedAt, isNull);
    });

    test('o pedido é estrito: campo fora do contrato continua sendo recusado '
        '(E-REQ-01)', () {
      final json = {
        ...EntryCodec.fromEntry(_entry()).toJson(),
        'revisedBy': 'alguém',
      };

      expect(() => CreateEntryRequest.fromJson(json), throwsFormatException);
    });
  });
}
