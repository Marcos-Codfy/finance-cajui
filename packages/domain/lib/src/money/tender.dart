/// As duas moedas do Cajui (RN-110).
///
/// Cada valor pertence a exatamente uma delas, e **nenhum total soma as duas**
/// (RN-111): o vale alimentação só paga comida, então somá-lo ao dinheiro
/// daria um número que não paga o aluguel.
enum Tender {
  /// Dinheiro: conta, Pix, débito, crédito, espécie.
  cash,

  /// Vale alimentação: saldo à parte, que só paga categoria elegível.
  mealVoucher,
}
