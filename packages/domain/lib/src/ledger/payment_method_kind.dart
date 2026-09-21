import 'package:domain/src/money/tender.dart';

/// Os tipos de forma de pagamento: **por onde** o dinheiro saiu.
enum PaymentMethodKind {
  /// Dinheiro vivo.
  physicalCash,

  /// Pix.
  pix,

  /// Cartão de débito.
  debit,

  /// Boleto.
  bankSlip,

  /// Cartão de crédito. É forma de pagamento, nunca despesa: a compra conta
  /// pelo que foi comprado, e a fatura é só uma visão calculada.
  creditCard,

  /// Vale alimentação.
  mealVoucher;

  /// A moeda da forma de pagamento (RN-205): só o vale é vale; o resto é
  /// dinheiro.
  Tender get tender =>
      this == PaymentMethodKind.mealVoucher ? Tender.mealVoucher : Tender.cash;

  /// A compra só sai da conta depois, na fatura.
  bool get isCreditCard => this == PaymentMethodKind.creditCard;
}
