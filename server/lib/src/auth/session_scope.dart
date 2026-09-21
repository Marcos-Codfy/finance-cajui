/// O que uma sessão pode fazer.
enum SessionScope {
  /// O app Android: lê e escreve.
  device,

  /// A web pareada: **só lê**. A regra é imposta aqui, no servidor — não é só
  /// a interface que esconde o botão (T-12).
  webReadOnly,
}
