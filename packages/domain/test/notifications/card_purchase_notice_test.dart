import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'notice_case.dart';

/// As compras no cartão, como cada banco as avisa. Textos fictícios, no
/// formato em que os apps escrevem.
void main() {
  group('RN-786 · compra no cartão vira leitura', () {
    test(r'Nubank: "Compra de R$ 45,90 APROVADA em ..."', () {
      expectReading(
        readNotice(
          BankApp.nubank,
          'Compra aprovada',
          r'Compra de R$ 45,90 APROVADA em MERCADO BOM PRECO para o '
              'cartão com final 1234.',
        ),
        kind: MovementKind.creditPurchase,
        cents: 4590,
        counterpart: 'MERCADO BOM PRECO',
        digits: '1234',
      );
    });

    test('Nubank no débito', () {
      expectReading(
        readNotice(
          BankApp.nubank,
          'Compra no débito aprovada',
          r'Compra de R$ 12,50 no débito APROVADA em PADARIA SOL NASCENTE.',
        ),
        kind: MovementKind.debitPurchase,
        cents: 1250,
        counterpart: 'PADARIA SOL NASCENTE',
      );
    });

    test('Inter: valor antes do lugar, cartão de crédito dito', () {
      expectReading(
        readNotice(
          BankApp.inter,
          'Compra aprovada',
          r'Compra aprovada: R$ 120,00 em POSTO ESTRELA no cartão de '
              'crédito final 4321',
        ),
        kind: MovementKind.creditPurchase,
        cents: 12000,
        counterpart: 'POSTO ESTRELA',
        digits: '4321',
      );
    });

    test('Itaú: data antes do lugar e o limite que sobrou no fim', () {
      expectReading(
        readNotice(
          BankApp.itau,
          'Itaú',
          r'Compra aprovada no cartão final 5678, de R$ 89,90, em 10/10 às '
              r'12:30, em FARMACIA BOA SAUDE. Limite disponível: R$ 1.234,56.',
        ),
        kind: MovementKind.creditPurchase,
        cents: 8990,
        counterpart: 'FARMACIA BOA SAUDE',
        digits: '5678',
      );
    });

    test('Itaú no débito, com o lugar no rótulo "Local:"', () {
      expectReading(
        readNotice(
          BankApp.itau,
          'Itaú',
          'ITAU DEBITO: Cartao final 5678 COMPRA APROVADA 10/10 12:30 '
              r'R$ 45,00 Local: SUPERMERCADO ALVORADA.',
        ),
        kind: MovementKind.debitPurchase,
        cents: 4500,
        counterpart: 'SUPERMERCADO ALVORADA',
      );
    });

    test('Caixa: o lugar vem antes do valor', () {
      expectReading(
        readNotice(
          BankApp.caixa,
          'CAIXA',
          r'CAIXA: Compra aprovada MERCADO PRECO BOM R$ 45,90 10/10 12:30 '
              'ELO final 1234',
        ),
        kind: MovementKind.creditPurchase,
        cents: 4590,
        counterpart: 'MERCADO PRECO BOM',
        digits: '1234',
      );
    });

    test('Banco do Brasil: "aprovada" no fim da frase', () {
      expectReading(
        readNotice(
          BankApp.bancoDoBrasil,
          'BB',
          r'BB: Compra no cartão final 9012 de R$ 78,30 em ACOUGUE BOI GORDO '
              'aprovada.',
        ),
        kind: MovementKind.creditPurchase,
        cents: 7830,
        counterpart: 'ACOUGUE BOI GORDO',
        digits: '9012',
      );
    });

    test('Santander: o lugar entre o valor e a data', () {
      expectReading(
        readNotice(
          BankApp.santander,
          'Santander',
          'Santander: Compra aprovada no cartão final 3456 no valor de '
              r'R$ 230,00 em LOJAS FICTICIAS em 10/10 às 12h30.',
        ),
        kind: MovementKind.creditPurchase,
        cents: 23000,
        counterpart: 'LOJAS FICTICIAS',
      );
    });

    test('C6: a bandeira no meio da frase', () {
      expectReading(
        readNotice(
          BankApp.c6,
          'Compra aprovada',
          r'Compra aprovada no C6 Mastercard final 7890 de R$ 64,00 em '
              'RESTAURANTE SABOR',
        ),
        kind: MovementKind.creditPurchase,
        cents: 6400,
        counterpart: 'RESTAURANTE SABOR',
        digits: '7890',
      );
    });

    test('Bradesco: o lugar depois da hora', () {
      expectReading(
        readNotice(
          BankApp.bradesco,
          'Bradesco',
          r'Bradesco: Compra aprovada no cartão final 2468 valor R$ 45,90 em '
              '10/10 às 12:30 PADARIA TRIGO BOM.',
        ),
        kind: MovementKind.creditPurchase,
        cents: 4590,
        counterpart: 'PADARIA TRIGO BOM',
      );
    });

    test('Neon: "no valor de"', () {
      expectReading(
        readNotice(
          BankApp.neon,
          'Neon',
          r'Compra aprovada no valor de R$ 32,50 em LANCHONETE DO ZE',
        ),
        kind: MovementKind.creditPurchase,
        cents: 3250,
        counterpart: 'LANCHONETE DO ZE',
      );
    });

    test('Mercado Pago no cartão de crédito', () {
      expectReading(
        readNotice(
          BankApp.mercadoPago,
          'Compra aprovada',
          r'Compra aprovada no cartão de crédito: R$ 89,90 em LOJA EXEMPLO',
        ),
        kind: MovementKind.creditPurchase,
        cents: 8990,
        counterpart: 'LOJA EXEMPLO',
      );
    });

    test('Mercado Pago com o saldo da conta é débito', () {
      expectReading(
        readNotice(
          BankApp.mercadoPago,
          'Pagamento aprovado',
          r'Você pagou R$ 45,90 a SORVETERIA GELADA.',
        ),
        kind: MovementKind.debitPurchase,
        cents: 4590,
        counterpart: 'SORVETERIA GELADA',
      );
    });

    test('PicPay: pagamento com o saldo e compra no PicPay Card', () {
      expectReading(
        readNotice(
          BankApp.picPay,
          'PicPay',
          r'Pagamento de R$ 22,90 aprovado em CAFETERIA AROMA',
        ),
        kind: MovementKind.debitPurchase,
        cents: 2290,
        counterpart: 'CAFETERIA AROMA',
      );
      expectReading(
        readNotice(
          BankApp.picPay,
          'PicPay Card',
          r'Compra no PicPay Card de R$ 59,90 aprovada em LIVRARIA PAGINA',
        ),
        kind: MovementKind.creditPurchase,
        cents: 5990,
        counterpart: 'LIVRARIA PAGINA',
      );
    });

    test('Google Wallet: o lugar é o título', () {
      expectReading(
        readNotice(
          BankApp.googleWallet,
          'MERCADO BOM PRECO',
          r'R$ 45,90 com Visa •••• 1234',
        ),
        kind: MovementKind.creditPurchase,
        cents: 4590,
        counterpart: 'MERCADO BOM PRECO',
        digits: '1234',
      );
    });

    test('Samsung Wallet: pagamento por aproximação', () {
      expectReading(
        readNotice(
          BankApp.samsungWallet,
          'Samsung Wallet',
          r'Pagamento de R$ 45,90 em MERCADO BOM PRECO concluído',
        ),
        kind: MovementKind.creditPurchase,
        cents: 4590,
        counterpart: 'MERCADO BOM PRECO',
      );
    });

    test('RN-311 · compra parcelada diz em quantas vezes', () {
      final reading = readNotice(
        BankApp.nubank,
        'Compra aprovada',
        r'Compra parcelada de R$ 300,00 em 3x aprovada em LOJA EXEMPLO',
      );
      expectReading(
        reading,
        kind: MovementKind.creditPurchase,
        cents: 30000,
        counterpart: 'LOJA EXEMPLO',
      );
      expect(reading!.installments, 3);
      expect(reading.isInstallment, isTrue);
    });
  });
}
