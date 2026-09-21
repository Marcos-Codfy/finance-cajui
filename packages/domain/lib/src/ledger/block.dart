/// Os três blocos de despesa do Cajui. Cada categoria pertence a exatamente
/// um (RN-202).
///
/// Não existe bloco "cartão": cartão de crédito é forma de pagamento, nunca
/// despesa (RN-207).
enum Block {
  /// Custo que se repete com valor conhecido: aluguel, internet.
  fixed,

  /// Gasto que oscila dentro de uma faixa, planejado pelo pior caso: mercado,
  /// transporte, lazer.
  variable,

  /// Parcelas de dívida, juros e tarifas.
  debt,
}
