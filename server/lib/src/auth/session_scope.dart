/// O que uma sessão pode fazer.
enum SessionScope {
  /// Quem tem a chave da casa: lê e escreve.
  device,

  /// Só lê. A regra é imposta aqui, no servidor — não é só a interface que
  /// esconde o botão (T-12). Hoje nenhuma entrada dá este escopo; fica para
  /// a sessão de consulta do login com código (ADR-024).
  webReadOnly,
}
