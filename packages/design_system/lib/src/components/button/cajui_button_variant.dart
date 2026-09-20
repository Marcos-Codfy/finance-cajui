/// O peso de um botão na tela.
///
/// A regra da marca é um acento por tela: no máximo um botão [primary] visível
/// de cada vez. Dois acentos competindo anulam os dois.
enum CajuiButtonVariant {
  /// A ação principal da tela. Um por tela.
  primary,

  /// Ação de apoio.
  secondary,

  /// Ação discreta, só texto: "Agora não", "Ver a conta".
  ghost,

  /// Ação que apaga ou desfaz algo sem volta. É o único botão que usa
  /// `intent.danger`.
  destructive,
}
