/// A natureza de um número do contexto (RN-918): a resposta precisa dizer se
/// fala do que já aconteceu, do que está no plano ou de uma estimativa.
enum ContextNumberKind {
  /// Já aconteceu: vem dos lançamentos.
  fact,

  /// Está no plano.
  plan,

  /// É estimativa.
  projection,
}
