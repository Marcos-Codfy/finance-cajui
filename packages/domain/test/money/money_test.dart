import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('RN-101 guarda centavos inteiros, e a soma é exata', () {
      // Em ponto flutuante, 0,10 + 0,20 não é 0,30.
      final sum = const Money.fromCents(10) + const Money.fromCents(20);

      expect(sum, const Money.fromCents(30));
      expect(const Money.fromCents(128450).cents, 128450);
    });

    test('RN-102 dividir em partes nunca perde nem inventa centavo', () {
      final parts = const Money.fromCents(10000).split(3);

      expect(parts.map((part) => part.cents), [3334, 3333, 3333]);
      expect(parts.reduce((a, b) => a + b), const Money.fromCents(10000));
    });

    test('RN-102 dividir em uma parte devolve o próprio valor', () {
      expect(const Money.fromCents(999).split(1), [const Money.fromCents(999)]);
    });

    test('RN-103 fração de centavo arredonda para o mais próximo', () {
      // 264,20 ÷ 3 = 88,0666… → 88,07
      expect(
        Money.ratio(const Money.fromCents(26420), 1, 3),
        const Money.fromCents(8807),
      );
      // 0,5 centavo sobe: 0,05 ÷ 2 = 0,025 → 0,03
      expect(
        Money.ratio(const Money.fromCents(5), 1, 2),
        const Money.fromCents(3),
      );
    });

    test('RN-103 limite de gasto arredonda para baixo', () {
      // 770,00 × 5 ÷ 17 = 226,4705… → 226,47
      expect(
        Money.ratioFloor(const Money.fromCents(77000), 5, 17),
        const Money.fromCents(22647),
      );
      // 0,99… nunca vira 1,00
      expect(
        Money.ratioFloor(const Money.fromCents(199), 1, 2),
        const Money.fromCents(99),
      );
    });

    test('a diferença pode ser negativa: é assim que a falta aparece', () {
      final shortfall =
          const Money.fromCents(320000) - const Money.fromCents(334200);

      expect(shortfall, const Money.fromCents(-14200));
      expect(shortfall.isNegative, isTrue);
      expect(shortfall.orZeroIfNegative, Money.zero);
    });

    test('compara e ordena pelo valor', () {
      final sorted = [
        const Money.fromCents(300),
        const Money.fromCents(-100),
        Money.zero,
      ]..sort();

      expect(sorted.map((money) => money.cents), [-100, 0, 300]);
      expect(const Money.fromCents(2) > const Money.fromCents(1), isTrue);
    });
  });

  group('TenderAmounts', () {
    test('RN-111 soma moeda a moeda, e não existe total geral', () {
      const income = TenderAmounts(
        cash: Money.fromCents(320000),
        mealVoucher: Money.fromCents(65000),
      );
      final spent = TenderAmounts.single(
        Tender.mealVoucher,
        const Money.fromCents(3840),
      );

      final left = income - spent;

      expect(left.cash, const Money.fromCents(320000));
      expect(left.mealVoucher, const Money.fromCents(61160));
      expect(left.of(Tender.mealVoucher), const Money.fromCents(61160));
    });

    test('RN-110 um valor avulso pertence a uma moeda só', () {
      final amounts = TenderAmounts.single(
        Tender.cash,
        const Money.fromCents(500),
      );

      expect(amounts.cash, const Money.fromCents(500));
      expect(amounts.mealVoucher, Money.zero);
    });
  });
}
