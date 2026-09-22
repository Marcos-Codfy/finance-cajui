/// O que a pergunta está pedindo, quando o próprio Cajui já sabe a resposta.
///
/// Existe por economia e por exatidão, nesta ordem de importância invertida:
/// a conta que o domínio faz é **exata**, e a que a IA faz é uma redação
/// sobre números que alguém lhe entregou. Quando a pergunta cabe aqui, não há
/// motivo para mandá-la para fora — e não se gasta token, nem internet, nem
/// os oito segundos de espera.
///
/// Só entram intenções que o domínio responde **inteiras**, com número
/// fechado. Pergunta aberta — "vale a pena trocar de plano?" — é [unknown] de
/// propósito: para essa, a IA existe.
enum QuestionIntent {
  /// Quanto ainda dá para gastar nesta semana (RN-641 a RN-647).
  weekLimit,

  /// Como o mês está fechando: sobra prevista, resultado, blocos (RN-620).
  monthClosing,

  /// Para onde foi o dinheiro do mês, por categoria (RN-643).
  whereMoneyWent,

  /// Quanto resta no vale alimentação (RN-120 a RN-123).
  voucherBalance,

  /// Quanto está reservado e quanto vem na fatura do cartão (RN-330).
  cardBill,

  /// Quanto ainda falta nas dívidas, e quando elas acabam (RN-510, RN-531).
  debts,

  /// O resumo de hoje (RN-810 a RN-812).
  today,

  /// Nenhuma das acima. Aqui a IA entra.
  unknown,
}
