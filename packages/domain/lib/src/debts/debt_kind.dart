/// Os tipos de dívida (RN-502).
enum DebtKind {
  /// Empréstimo.
  loan,

  /// Financiamento.
  financing,

  /// Parcelamento de uma compra no cartão. Não gera lançamento novo quando
  /// vence: o lançamento é a compra original, e a parcela é cobrada na fatura
  /// (RN-521).
  cardInstallment,

  /// Rotativo do cartão ou parcelamento de fatura: o que sobra quando a
  /// fatura é paga em parte (RN-342).
  cardRevolving,

  /// Dinheiro devido a uma pessoa.
  informal,
}
