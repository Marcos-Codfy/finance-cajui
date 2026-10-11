import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'notice_case.dart';

/// Pix, transferências e boletos, como cada banco os avisa. Textos e nomes
/// fictícios.
void main() {
  group('RN-786 · dinheiro que saiu', () {
    test('Nubank: transferência enviada', () {
      expectReading(
        readNotice(
          BankApp.nubank,
          'Transferência enviada',
          r'Você enviou uma transferência de R$ 50,00 para Fulano de Tal.',
        ),
        kind: MovementKind.transferSent,
        cents: 5000,
        counterpart: 'Fulano de Tal',
      );
    });

    test('Pix enviado, do jeito de cada banco', () {
      final cases = {
        BankApp.inter: r'Pix enviado com sucesso: R$ 75,00 para Beltrano Silva',
        BankApp.neon: r'Pix enviado no valor de R$ 75,00 para Beltrano Silva',
        BankApp.bancoDoBrasil: r'Pix enviado: R$ 75,00 para Beltrano Silva',
        BankApp.santander: r'Pix de R$ 75,00 enviado para Beltrano Silva',
        BankApp.caixa: r'Pix enviado no valor de R$ 75,00 para Beltrano Silva',
        BankApp.itau: r'Pix realizado: R$ 75,00 para Beltrano Silva',
        BankApp.c6: r'Você fez um Pix de R$ 75,00 para Beltrano Silva',
        BankApp.picPay: r'Você fez um Pix de R$ 75,00 para Beltrano Silva.',
      };
      for (final MapEntry(key: app, value: text) in cases.entries) {
        final reading = readNotice(app, 'Pix', text);
        expect(reading?.kind, MovementKind.pixSent, reason: app.label);
        expect(reading?.amount, const Money.fromCents(7500), reason: text);
        expect(reading?.counterpart, 'Beltrano Silva', reason: text);
      }
    });

    test('Bradesco: o nome no rótulo "Favorecido:"', () {
      expectReading(
        readNotice(
          BankApp.bradesco,
          'Pix enviado',
          r'Pix enviado. Valor: R$ 60,00. Favorecido: BELTRANO EXEMPLO',
        ),
        kind: MovementKind.pixSent,
        cents: 6000,
        counterpart: 'BELTRANO EXEMPLO',
      );
    });

    test('Mercado Pago: "Você transferiu"', () {
      expectReading(
        readNotice(
          BankApp.mercadoPago,
          'Transferência',
          r'Você transferiu R$ 30,00 para Fulano Exemplo.',
        ),
        kind: MovementKind.transferSent,
        cents: 3000,
        counterpart: 'Fulano Exemplo',
      );
    });

    test('Inter: boleto pago', () {
      expectReading(
        readNotice(
          BankApp.inter,
          'Boleto',
          r'Pagamento de boleto realizado: R$ 210,35',
        ),
        kind: MovementKind.boletoPaid,
        cents: 21035,
      );
    });

    test('a forma de pagamento de cada movimentação', () {
      expect(
        MovementKind.creditPurchase.paymentKind,
        PaymentMethodKind.creditCard,
      );
      expect(MovementKind.debitPurchase.paymentKind, PaymentMethodKind.debit);
      expect(MovementKind.pixSent.paymentKind, PaymentMethodKind.pix);
      expect(MovementKind.transferSent.paymentKind, PaymentMethodKind.pix);
      expect(MovementKind.boletoPaid.paymentKind, PaymentMethodKind.bankSlip);
      expect(MovementKind.pixReceived.paymentKind, isNull);
    });
  });

  group('RN-788 · dinheiro que entrou', () {
    test('Nubank: transferência recebida', () {
      final reading = readNotice(
        BankApp.nubank,
        'Transferência recebida',
        r'Você recebeu uma transferência de R$ 150,00 de Fulano de Tal.',
      );
      expectReading(
        reading,
        kind: MovementKind.transferReceived,
        cents: 15000,
        counterpart: 'Fulano de Tal',
      );
      expect(reading!.kind.isIncoming, isTrue);
    });

    test('Pix recebido, do jeito de cada banco', () {
      final cases = {
        BankApp.mercadoPago: r'Você recebeu R$ 100,00 de Ciclano Exemplo',
        BankApp.picPay: r'Você recebeu R$ 100,00 de Ciclano Exemplo',
        BankApp.inter: r'Pix recebido: R$ 100,00 de Ciclano Exemplo',
        BankApp.c6: r'Pix recebido de Ciclano Exemplo no valor de R$ 100,00',
        BankApp.bancoDoBrasil:
            r'Você recebeu um Pix de R$ 100,00 de Ciclano Exemplo',
        BankApp.bradesco:
            r'Pix recebido. Valor: R$ 100,00. Remetente: Ciclano Exemplo',
      };
      for (final MapEntry(key: app, value: text) in cases.entries) {
        final reading = readNotice(app, 'Pix', text);
        expect(reading?.kind, MovementKind.pixReceived, reason: app.label);
        expect(reading?.amount, const Money.fromCents(10000), reason: text);
        expect(reading?.counterpart, 'Ciclano Exemplo', reason: text);
        expect(reading?.kind.isIncoming, isTrue);
      }
    });
  });
}
