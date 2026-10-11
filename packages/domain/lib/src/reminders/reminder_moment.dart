/// Os dois momentos de um lembrete de vencimento (RN-840): dois dias antes,
/// para dar tempo de separar o dinheiro, e no dia. Não existe um terceiro
/// depois do vencimento — lembrete em cascata vira cobrança.
enum ReminderMoment {
  /// Dois dias antes do vencimento.
  twoDaysBefore(2),

  /// No dia do vencimento.
  onTheDay(0);

  new(this.daysBefore);

  /// Quantos dias antes do vencimento o lembrete chega.
  final int daysBefore;
}
