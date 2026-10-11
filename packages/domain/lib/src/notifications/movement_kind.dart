import 'package:domain/src/ledger/payment_method_kind.dart';

/// Que movimentação de dinheiro uma notificação de banco avisa.
enum MovementKind {
  /// Compra no cartão de crédito.
  creditPurchase,

  /// Compra no débito, ou pagamento com o saldo da conta.
  debitPurchase,

  /// Pix enviado.
  pixSent,

  /// Pix recebido.
  pixReceived,

  /// Boleto pago.
  boletoPaid,

  /// Transferência (TED, DOC, entre bancos) enviada.
  transferSent,

  /// Transferência recebida.
  transferReceived;

  /// Dinheiro que **entrou**: nunca vira despesa (RN-758), e nunca é
  /// lançado sozinho (RN-788).
  bool get isIncoming => this == pixReceived || this == transferReceived;

  /// Por onde o dinheiro saiu. A transferência sai da conta como o Pix, e é
  /// como Pix que ela entra no livro: é o que a pessoa reconhece.
  PaymentMethodKind? get paymentKind => switch (this) {
    creditPurchase => PaymentMethodKind.creditCard,
    debitPurchase => PaymentMethodKind.debit,
    pixSent || transferSent => PaymentMethodKind.pix,
    boletoPaid => PaymentMethodKind.bankSlip,
    pixReceived || transferReceived => null,
  };

  /// O nome da movimentação, para quando o banco não diz com quem foi.
  String get label => switch (this) {
    creditPurchase => 'Compra no crédito',
    debitPurchase => 'Compra no débito',
    pixSent => 'Pix enviado',
    pixReceived => 'Pix recebido',
    boletoPaid => 'Boleto',
    transferSent => 'Transferência enviada',
    transferReceived => 'Transferência recebida',
  };
}
