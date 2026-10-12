/// O que a pessoa disse que uma linha de extrato é, quando o tipo ficou em
/// dúvida (RN-1114) — e o que a memória repete nos meses seguintes
/// (RN-1116).
enum LineTreatment {
  /// "É um gasto": entra no mês, com a categoria.
  expense,

  /// "É dinheiro que entrou": um Pix recebido de alguém de fora da casa,
  /// que conta como entrada.
  income,

  /// "Alguém da casa": dinheiro mudando de conta dentro da casa; não é
  /// gasto nem renda (RN-1070).
  household,

  /// "Conta minha": transferência entre contas suas; não é gasto (RN-759).
  ownAccount,

  /// "Não lançar": fica fora, sem explicação.
  ignore,
}
