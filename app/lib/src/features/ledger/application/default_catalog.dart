import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// O cadastro com que o app nasce: categorias e formas de pagamento comuns a
/// quase toda casa, para o primeiro lançamento não exigir configuração.
///
/// Cartão de crédito fica de fora de propósito. Ele precisa de dia de
/// fechamento e de vencimento para a fatura existir, e isso chega com o
/// cadastro de cartão — forma de pagamento pela metade seria pior que nenhuma.
abstract final class DefaultCatalog {
  /// As categorias iniciais. As de comida nascem elegíveis ao vale (RN-113).
  static const categories = [
    Category(
      id: 'groceries',
      name: 'Mercado',
      block: Block.variable,
      groupId: 'food',
      voucherEligible: true,
    ),
    Category(
      id: 'street-market',
      name: 'Feira',
      block: Block.variable,
      groupId: 'food',
      voucherEligible: true,
    ),
    Category(
      id: 'butcher',
      name: 'Açougue',
      block: Block.variable,
      groupId: 'food',
      voucherEligible: true,
    ),
    Category(
      id: 'bakery',
      name: 'Padaria',
      block: Block.variable,
      groupId: 'food',
      voucherEligible: true,
    ),
    Category(
      id: 'produce',
      name: 'Hortifrúti',
      block: Block.variable,
      groupId: 'food',
      voucherEligible: true,
    ),
    Category(
      id: 'eating-out',
      name: 'Restaurante e lanche',
      block: Block.variable,
      groupId: 'food',
    ),
    Category(
      id: 'transport',
      name: 'Transporte',
      block: Block.variable,
      groupId: 'transport',
    ),
    Category(
      id: 'health',
      name: 'Saúde e farmácia',
      block: Block.variable,
      groupId: 'health',
    ),
    Category(
      id: 'leisure',
      name: 'Lazer',
      block: Block.variable,
      groupId: 'leisure',
    ),
    Category(
      id: 'home',
      name: 'Casa',
      block: Block.variable,
      groupId: 'housing',
    ),
    Category(
      id: 'rent',
      name: 'Aluguel',
      block: Block.fixed,
      groupId: 'housing',
    ),
    Category(
      id: 'utilities',
      name: 'Água, luz e internet',
      block: Block.fixed,
      groupId: 'housing',
    ),
  ];

  /// As formas de pagamento iniciais.
  static const paymentMethods = [
    PaymentMethod(id: 'pix', name: 'Pix', kind: PaymentMethodKind.pix),
    PaymentMethod(id: 'debit', name: 'Débito', kind: PaymentMethodKind.debit),
    PaymentMethod(
      id: 'cash',
      name: 'Dinheiro vivo',
      kind: PaymentMethodKind.physicalCash,
    ),
    PaymentMethod(
      id: 'voucher',
      name: 'Vale alimentação',
      kind: PaymentMethodKind.mealVoucher,
    ),
    PaymentMethod(
      id: 'bank-slip',
      name: 'Boleto',
      kind: PaymentMethodKind.bankSlip,
    ),
  ];

  /// O livro de quem acabou de instalar o app: o cadastro e mais nada.
  static LedgerBook get emptyBook =>
      LedgerBook(categories: categories, paymentMethods: paymentMethods);
}
