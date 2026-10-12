/// Os grupos do menu da gallery, na ordem em que aparecem.
///
/// A ordem é a de quem chega frio: primeiro o que o Cajui é, depois o app
/// funcionando, o movimento e o som, e só então as peças e os fundamentos.
/// Começar pelas amostras de cor escondia o que o projeto tem de especial.
enum GalleryGroup {
  /// A porta de entrada.
  start('Comece aqui'),

  /// As telas do app, em todos os estados.
  app('O app'),

  /// O 3D, as microinterações, as curvas e os sons.
  motion('Movimento e som'),

  /// Os componentes, cada um com os seus estados.
  components('Componentes'),

  /// Cor, contraste, tipo, espaço e ícones.
  foundations('Fundamentos');

  new(this.title);

  /// O nome do grupo no menu.
  final String title;
}
