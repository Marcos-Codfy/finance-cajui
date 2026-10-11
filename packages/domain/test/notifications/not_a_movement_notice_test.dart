import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'notice_case.dart';

/// O que chega dos bancos e não é movimentação de dinheiro: nada disso
/// pode virar lançamento. Textos fictícios.
void main() {
  group('RN-787 · não é movimentação, e não vira nada', () {
    final cases = <(BankApp, String, String)>[
      (BankApp.nubank, 'Sua fatura fechou', r'A fatura fechou em R$ 1.234,56.'),
      (
        BankApp.nubank,
        'Pagamento recebido',
        r'Recebemos o pagamento de R$ 800,00 da sua fatura.',
      ),
      (
        BankApp.inter,
        'Pix',
        r'Pix enviado para pagamento da fatura: R$ 500,00',
      ),
      (BankApp.itau, 'Saldo', r'Seu saldo é de R$ 2.000,00'),
      (BankApp.bancoDoBrasil, 'BB', 'Seu código de acesso é 123456'),
      (
        BankApp.c6,
        'Limite',
        r'Você usou 80% do limite do seu cartão. Limite disponível: R$ 300,00',
      ),
      (
        BankApp.picPay,
        'Oferta',
        r'Ganhe R$ 10,00 de cashback na sua próxima compra',
      ),
      (
        BankApp.nubank,
        'Compra negada',
        r'Compra de R$ 45,90 NEGADA em MERCADO X. Saldo insuficiente.',
      ),
      (
        BankApp.santander,
        'Pix agendado',
        r'Pix agendado de R$ 50,00 para Fulano Exemplo',
      ),
      (
        BankApp.bradesco,
        'Empréstimo',
        r'Empréstimo pré-aprovado de R$ 5.000,00',
      ),
      (BankApp.caixa, 'Estorno', r'Estorno de R$ 45,90 da compra em MERCADO X'),
      (BankApp.neon, 'Compra aprovada', 'Sua compra foi aprovada.'),
      (BankApp.inter, 'Boleto', r'Seu boleto de R$ 99,90 vence amanhã'),
      (
        BankApp.mercadoPago,
        'Rendeu',
        r'Seu dinheiro rendeu R$ 3,20 esta semana',
      ),
    ];
    for (final (app, title, text) in cases) {
      test('${app.label}: "$text"', () {
        expect(readNotice(app, title, text), isNull);
      });
    }

    test('notificação de app que não é banco da lista não é lida', () {
      final reading = BankNotificationParser.read(
        BankNotification(
          packageName: 'com.exemplo.mensagens',
          title: 'Compra aprovada',
          text: r'Compra de R$ 45,90 aprovada em MERCADO X',
          postedOn: noticeDay,
        ),
      );
      expect(reading, isNull);
    });
  });

  group('o valor', () {
    test('milhar com ponto, sem espaço, com espaço que não quebra', () {
      final nbsp = String.fromCharCode(0xA0);
      final cases = {
        r'Compra de R$ 1.234,56 aprovada em LOJA X': 123456,
        r'Compra de R$45,90 aprovada em LOJA X': 4590,
        'Compra de R\$${nbsp}45,90 aprovada em LOJA X': 4590,
        r'Compra de R$ 10 aprovada em LOJA X': 1000,
      };
      for (final MapEntry(key: text, value: cents) in cases.entries) {
        final reading = readNotice(BankApp.nubank, 'Compra', text);
        expect(reading?.amount, Money.fromCents(cents), reason: text);
      }
    });

    test('o limite que vem antes da compra não é o valor dela', () {
      final reading = readNotice(
        BankApp.bancoDoBrasil,
        'BB',
        r'Limite disponível R$ 1.000,00. Compra de R$ 45,90 aprovada em '
            'LOJA X',
      );
      expect(reading?.amount, const Money.fromCents(4590));
    });
  });

  group('os bancos da lista', () {
    test('o pacote diz o banco', () {
      expect(BankApp.ofPackage('com.nu.production'), BankApp.nubank);
      expect(BankApp.ofPackage('br.gov.caixa.tem'), BankApp.caixa);
      expect(BankApp.ofPackage('com.exemplo'), isNull);
      expect(BankApp.allPackages, contains('br.com.intermedium'));
    });

    test('RN-789 · o nome do cartão cadastrado diz de que banco ele é', () {
      expect(BankApp.nubank.namesCard('Roxinho'), isTrue);
      expect(BankApp.nubank.namesCard('Cartão Nubank'), isTrue);
      expect(BankApp.itau.namesCard('Itaú Click'), isTrue);
      expect(BankApp.bancoDoBrasil.namesCard('Ourocard Visa'), isTrue);
      expect(BankApp.inter.namesCard('Internet'), isFalse);
      expect(BankApp.nubank.namesCard('Inter'), isFalse);
      expect(BankApp.googleWallet.namesCard('Nubank'), isFalse);
    });
  });
}
