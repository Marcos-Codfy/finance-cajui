/// Os quatro grupos do que sai no mês, os mesmos da planilha do dono
/// (11/10/2026). Cada categoria pertence a exatamente um (RN-202).
///
/// Não existe grupo "cartão": cartão de crédito é forma de pagamento, nunca
/// despesa (RN-207).
///
/// Os nomes dos valores moram nos eventos guardados — `fixed`, `variable`,
/// `debt` desde a Fase 6 —, e por isso nunca mudam: o grupo novo entrou
/// somando, e o "Dia a dia" continua se chamando `variable` por dentro.
enum Block {
  /// Conta fixa: aluguel, energia, internet.
  fixed,

  /// Dia a dia: transporte, mercado, padaria, lanchonete, farmácia.
  variable,

  /// Parcela de dívida: vem da dívida cadastrada, nunca é digitada.
  debt,

  /// Assinatura: o serviço que se paga todo mês.
  subscription,
}
