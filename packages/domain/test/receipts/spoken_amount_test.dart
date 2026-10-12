import 'package:domain/domain.dart';
import 'package:test/test.dart';

int? _cents(String said) => SpokenAmount.of(said)?.cents;

void main() {
  group('RN-1091 · o valor dito, e não qualquer número da frase', () {
    test(
      'o número sozinho, com vírgula, com ponto de centavos e com milhar',
      () {
        expect(_cents('gastei 40 no mercado'), 4000);
        expect(_cents('comprei pão, 8,50 no débito'), 850);
        expect(_cents('paguei 8.50 de café'), 850);
        expect(_cents('paguei 1.200 de aluguel'), 120000);
        expect(_cents('paguei 1200 de aluguel'), 120000);
        expect(_cents('gastei 1.250,50 no mercado'), 125050);
      },
    );

    test(r'o número de "R$" ou de "reais" vence o primeiro da frase', () {
      expect(_cents(r'no dia 5 gastei R$ 35 no Uber'), 3500);
      expect(_cents('comprei 2 pães por 12 reais'), 1200);
      expect(_cents('gastei 40 reais e 50 centavos'), 4050);
    });

    test('dia, hora e data não são o valor', () {
      expect(_cents('dia 5 paguei 120 de luz'), 12000);
      expect(_cents('hoje às 10 gastei 40 no mercado'), 4000);
      expect(_cents('gastei 35 no Uber as 8h'), 3500);
      expect(_cents('em 11/10 paguei 90 de internet'), 9000);
      expect(_cents('às 10h30 paguei 15 de café'), 1500);
    });

    test('com parcela não há valor seguro: a conferência pergunta', () {
      expect(_cents('paguei 2x 50 no tênis'), isNull);
      expect(_cents('comprei um tênis em 3 vezes de 100'), isNull);
      expect(_cents('comprei a geladeira parcelada, 300'), isNull);
    });

    test('sem número, sem valor', () {
      expect(_cents('paguei a luz'), isNull);
    });
  });
}
