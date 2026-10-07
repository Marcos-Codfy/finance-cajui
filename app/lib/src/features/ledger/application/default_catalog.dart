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
    // O que não cabe em nenhuma: é onde cai o lançamento de quem só
    // digitou o valor, e de onde se tira com um toque.
    Category(
      id: 'other',
      name: 'Outros',
      block: Block.variable,
      groupId: 'other',
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
    // O pagamento de uma parcela de dívida é lançamento como qualquer outro
    // (RN-520); é o bloco que o separa do gasto do mês.
    Category(
      id: 'debt-installment',
      name: 'Parcela de dívida',
      block: Block.debt,
      groupId: 'debt',
    ),
    // Anuidade, juros, multa e tarifa cobrados na fatura são lançamentos
    // comuns, pagos com o próprio cartão (RN-333). Ficam no bloco de
    // dívidas, e não no de variáveis: não são escolha de gasto, são o preço
    // de ter a dívida — e misturá-los com o mercado faria o limite da
    // semana parecer estourado por algo que ninguém comprou.
    Category(
      id: 'interest-and-fees',
      name: 'Juros e tarifas',
      block: Block.debt,
      groupId: 'debt',
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

  /// O que cada ramo de estabelecimento significa neste cadastro.
  ///
  /// É o que faz um cupom de supermercado nascer como compra de mercado sem a
  /// IA: o domínio lê o ramo do nome da loja, e este mapa diz em que
  /// categoria ele cai. Quem muda as categorias muda isto junto.
  static const Map<MerchantKind, String> categoryByMerchantKind = {
    MerchantKind.supermarket: 'groceries',
    MerchantKind.streetMarket: 'street-market',
    MerchantKind.produce: 'produce',
    MerchantKind.butcher: 'butcher',
    MerchantKind.bakery: 'bakery',
    MerchantKind.dining: 'eating-out',
    MerchantKind.pharmacy: 'health',
    MerchantKind.fuel: 'transport',
  };

  /// O livro de quem acabou de instalar o app: o cadastro e mais nada.
  static LedgerBook get emptyBook =>
      LedgerBook(categories: categories, paymentMethods: paymentMethods);
}
