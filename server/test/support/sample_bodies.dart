/// Corpos de pedido prontos, para os testes das rotas não repetirem JSON.
library;

const Map<String, Object?> groceriesBody = {
  'id': 'groceries',
  'name': 'Mercado',
  'block': 'variable',
  'groupId': 'food',
  'voucherEligible': true,
};

Map<String, Object?> entryBody({
  String id = 'e1',
  int cents = 8600,
  String on = '2026-09-12',
  List<Map<String, Object?>>? lines,
}) => {
  'id': id,
  'description': 'Mercado Boa Compra',
  'amountCents': cents,
  'occurredOn': on,
  'categoryId': 'groceries',
  'paymentLines':
      lines ??
      [
        {
          'paymentMethodId': 'voucher',
          'kind': 'mealVoucher',
          'amountCents': 3000,
        },
        {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 5600},
      ],
};

/// Um plano de mês no formato de `POST /v1/plan`: renda, parcelas, uma conta
/// fixa e uma faixa de variável que o vale pode pagar.
Map<String, Object?> planBody({int cashIncomeCents = 320000}) => {
  'cashIncomeCents': cashIncomeCents,
  'debtInstallmentsCents': 45000,
  'fixed': [
    {
      'id': 'rent',
      'name': 'Aluguel',
      'amountCents': 120000,
      'dueDay': 5,
      'categoryId': 'housing',
      'paymentMethodId': 'pix',
    },
  ],
  'variables': [
    {
      'categoryId': 'groceries',
      'minCents': 40000,
      'maxCents': 60000,
      'voucherEligible': true,
    },
  ],
};

Map<String, Object?> errorOf(Map<String, Object?> body) =>
    body['error']! as Map<String, Object?>;
