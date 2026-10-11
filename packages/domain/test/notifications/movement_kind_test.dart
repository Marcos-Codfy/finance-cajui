import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-786 · o que cada movimentação do banco vira', () {
    test('RN-758 · dinheiro que entra nunca é despesa: não tem forma de '
        'pagamento', () {
      final incoming = MovementKind.values.where((kind) => kind.isIncoming);

      expect(incoming, [
        MovementKind.pixReceived,
        MovementKind.transferReceived,
      ]);
      expect([for (final kind in incoming) kind.paymentKind], [null, null]);
    });

    test('a transferência sai como o Pix, que é o que a pessoa reconhece; a '
        'compra, pelo cartão ou pelo débito; o boleto, como boleto', () {
      expect(
        {for (final kind in MovementKind.values) kind: kind.paymentKind},
        {
          MovementKind.creditPurchase: PaymentMethodKind.creditCard,
          MovementKind.debitPurchase: PaymentMethodKind.debit,
          MovementKind.pixSent: PaymentMethodKind.pix,
          MovementKind.pixReceived: null,
          MovementKind.boletoPaid: PaymentMethodKind.bankSlip,
          MovementKind.transferSent: PaymentMethodKind.pix,
          MovementKind.transferReceived: null,
        },
      );
    });

    test('sem o nome de quem, o lançamento leva o nome da movimentação', () {
      expect(
        [for (final kind in MovementKind.values) kind.label],
        [
          'Compra no crédito',
          'Compra no débito',
          'Pix enviado',
          'Pix recebido',
          'Boleto',
          'Transferência enviada',
          'Transferência recebida',
        ],
      );
    });
  });
}
