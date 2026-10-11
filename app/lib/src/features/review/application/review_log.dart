/// O que já foi revisto na revisão da semana (RN-871).
///
/// Fica só no aparelho: revisar é um gesto de quem usa este celular, e não
/// um fato do livro da casa — nada daqui sobe ao servidor.
abstract interface class ReviewLog {
  /// Os lançamentos já revistos.
  Future<Set<String>> reviewed();

  /// Marca [entryIds] como revistos.
  Future<void> markReviewed(Iterable<String> entryIds);
}
