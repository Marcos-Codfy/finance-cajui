/// Que tipo de toque um controle recebe, para o som que ele faz.
///
/// Cada família de controle soa do seu jeito, como o dono pediu ao trazer
/// os sons novos: o botão de ação dá o clique, e o card — cartão, linha de
/// lista, opção, barra de gráfico — dá o pop, mais leve. Chave e chip não
/// entram aqui: quem diz que o toque liga ou desliga é
/// `CajuiPressable.toggled`, e o som deles é o da chave.
enum CajuiTouch {
  /// Botão de ação: o clique.
  action,

  /// Card, linha de lista, opção ou barra de gráfico: o pop.
  card,
}
