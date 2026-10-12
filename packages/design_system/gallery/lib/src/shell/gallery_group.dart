/// Os grupos do menu da gallery, na ordem em que aparecem.
enum GalleryGroup {
  /// Tokens: cor, contraste, tipo, espaço.
  foundations('Fundação'),

  /// Os componentes, cada um com todos os estados.
  components('Componentes'),

  /// O 3D: rolagem, carrossel, entrada, carteira e a câmera entre telas,
  /// cada um num aparelho.
  depth('Profundidade'),

  /// Telas inteiras em cada estado.
  screens('Telas'),

  /// O que ainda espera uma escolha, com as opções lado a lado.
  decisions('Decisões'),

  /// Movimento e som.
  senses('Sentidos');

  new(this.title);

  /// O nome do grupo no menu.
  final String title;
}
