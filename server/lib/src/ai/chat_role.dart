/// Quem fala em cada mensagem de uma conversa com o modelo.
enum ChatRole {
  /// As instruções fixas e o contexto montado pelo servidor.
  system,

  /// A pessoa.
  user,

  /// O modelo — em texto ou pedindo uma ferramenta.
  assistant,

  /// O resultado de uma ferramenta, devolvido ao modelo.
  tool,
}
