/// A tela que o toque num lembrete de vencimento abre (RN-849, RN-1087).
///
/// É o assunto do lembrete, e não uma rota: o domínio não conhece tela. Quem
/// traduz o assunto em caminho é o app.
enum ReminderTarget {
  /// Conta de "Minhas contas": abre Minhas contas.
  bills,

  /// Parcela de dívida: abre Minhas dívidas.
  debts,

  /// Fatura de cartão: abre os cartões.
  cards,
}
