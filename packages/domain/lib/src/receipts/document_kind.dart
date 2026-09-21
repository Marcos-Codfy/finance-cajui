/// O que o comprovante é. Nem todo comprovante é uma compra — e tratar um
/// pagamento de fatura como despesa contaria o mesmo dinheiro duas vezes.
enum DocumentKind {
  /// Uma compra: vira proposta de lançamento.
  purchase,

  /// O pagamento da fatura de um cartão: vira liquidação, nunca despesa
  /// (RN-343 e RN-756).
  statementPayment,

  /// Dinheiro que entrou: vira recebimento, nunca lançamento (RN-758).
  incomeReceipt,

  /// Saque ou transferência entre contas próprias: não vira nada (RN-759).
  ownTransfer,
}
