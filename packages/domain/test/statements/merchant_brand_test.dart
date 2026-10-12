import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-1108 · a marca por trás do jeito como o extrato escreve', () {
    test('"IFD*RESTAURANTE SABOR" é iFood, pedido por aplicativo', () {
      final brand = MerchantBrand.of('IFD*RESTAURANTE SABOR')!;

      expect(brand.name, 'iFood');
      expect(brand.kind, MerchantKind.delivery);
      expect(MerchantBrand.of('Compra IFOOD.COM AGENCIA')!.name, 'iFood');
    });

    test('Uber Eats não é corrida, e Uberlândia não é Uber', () {
      expect(MerchantBrand.of('UBER *EATS PENDING')!.name, 'Uber Eats');
      expect(MerchantBrand.of('UBER *TRIP HELP.UBER.COM')!.name, 'Uber');
      expect(MerchantBrand.of('UBER *TRIP')!.kind, MerchantKind.rideHailing);
      expect(MerchantBrand.of('SUPERMERCADO UBERLANDIA'), isNull);
    });

    test('assinaturas: o nome é sempre o da tabela, nunca o do extrato', () {
      expect(MerchantBrand.of('NETFLIX.COM')!.name, 'Netflix');
      expect(MerchantBrand.of('APPLE.COM/BILL')!.name, 'Apple');
      expect(MerchantBrand.of('GOOGLE *YOUTUBE')!.name, 'YouTube');
      expect(MerchantBrand.of('Spotify P1A2B3')!.kind, MerchantKind.streaming);
    });

    test('o prefixo da maquininha sai e deixa o nome da loja', () {
      expect(
        MerchantBrand.withoutAcquirer('MP*PADARIA BOA VISTA'),
        'PADARIA BOA VISTA',
      );
      expect(
        MerchantBrand.withoutAcquirer('Compra PAG*ACOUGUE DO ZE'),
        'Compra ACOUGUE DO ZE',
      );
      // No meio de uma palavra, não é prefixo: "CAMP*" não perde o "MP*".
      expect(MerchantBrand.withoutAcquirer('CAMP*LOJA'), 'CAMP*LOJA');
    });

    test('a chave: a mesma marca de qualquer restaurante, e o mesmo lugar '
        'com ou sem maquininha', () {
      expect(
        MerchantBrand.keyOf('IFD*RESTAURANTE SABOR'),
        MerchantBrand.keyOf('IFD*PIZZARIA BELLA'),
      );
      expect(MerchantBrand.keyOf('IFD*PIZZARIA BELLA'), 'ifood');
      expect(
        MerchantBrand.keyOf('MP*PADARIA BOA VISTA'),
        MerchantBrand.keyOf('Padaria Boa Vista'),
      );
    });

    test('nome desconhecido não é marca nenhuma', () {
      expect(MerchantBrand.of('PADARIA BOA VISTA'), isNull);
    });
  });
}
