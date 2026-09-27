import 'package:domain/domain.dart';
import 'package:test/test.dart';

const _groceries = Category(
  id: 'groceries',
  name: 'Mercado',
  block: Block.variable,
  groupId: 'food',
  voucherEligible: true,
);

Entry _entry({DateTime? revisedAt}) => Entry.create(
  id: 'e1',
  description: 'Feira',
  amount: const Money.fromCents(8600),
  occurredOn: LocalDate(2026, 9, 20),
  category: _groceries,
  today: LocalDate(2026, 9, 20),
  paymentLines: const [
    PaymentLine(
      paymentMethodId: 'pix',
      kind: PaymentMethodKind.pix,
      amount: Money.fromCents(8600),
    ),
  ],
  revisedAt: revisedAt,
).valueOrNull!;

void main() {
  final earlier = DateTime.utc(2026, 9, 20, 12);
  final later = DateTime.utc(2026, 9, 21, 12);

  group('BL-062 · quem venceu entre duas edições', () {
    test('o carimbo mais novo vence, chegue quando chegar', () {
      expect(EditStamp.isNewer(later, earlier), isTrue);
      expect(EditStamp.isNewer(earlier, later), isFalse);
    });

    test('o mesmo instante não é mais novo: vale o que já está', () {
      expect(EditStamp.isNewer(later, later), isFalse);
    });

    test('sem carimbo aqui, nunca; sem carimbo lá, sempre', () {
      expect(EditStamp.isNewer(null, earlier), isFalse);
      expect(EditStamp.isNewer(earlier, null), isTrue);
    });

    test('sem carimbo dos dois lados, ninguém é mais novo', () {
      expect(EditStamp.isNewer(null, null), isFalse);
    });

    test('o lançamento e o plano usam a mesma régua', () {
      expect(_entry(revisedAt: later).isNewerThan(_entry()), isTrue);
      expect(_entry().isNewerThan(_entry(revisedAt: later)), isFalse);
      expect(
        const MonthSetup(cashIncome: Money.fromCents(1))
            .stamped(later)
            .isNewerThan(
              const MonthSetup(cashIncome: Money.fromCents(1)).stamped(earlier),
            ),
        isTrue,
      );
    });

    test(
      'o carimbo é guardado em UTC, seja qual for o fuso de quem editou',
      () {
        final local = DateTime(2026, 9, 20, 9);

        expect(_entry(revisedAt: local).revisedAt, local.toUtc());
        expect(_entry(revisedAt: local).revisedAt!.isUtc, isTrue);
      },
    );
  });
}
