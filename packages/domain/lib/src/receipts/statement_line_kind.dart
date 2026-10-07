/// O que uma movimentação de extrato é. Só a despesa vira lançamento por
/// padrão; o resto aparece na lista para a pessoa ver que foi lido.
enum StatementLineKind {
  /// Dinheiro que saiu para uma compra ou conta: vira lançamento.
  expense,

  /// Dinheiro que entrou: vira recebimento, nunca despesa (RN-758).
  income,

  /// Pagamento da fatura do cartão: não é despesa — as compras já contaram
  /// quando foram feitas (RN-756).
  cardPayment,

  /// Saque ou transferência entre contas da própria pessoa: não vira nada
  /// (RN-759).
  ownTransfer,
}
