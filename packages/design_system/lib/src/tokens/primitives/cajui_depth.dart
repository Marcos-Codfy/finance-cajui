/// A câmera do Cajui: a perspectiva e os limites de tudo o que tem
/// profundidade.
///
/// Cartão que vira, rolagem que curva nas bordas, carrossel que gira e bloco
/// que chega de longe usam a mesma lente. Com lentes diferentes, cada efeito
/// seria bonito sozinho e estranho ao lado do outro — a tela pareceria
/// montada com peças de apps diferentes.
abstract final class CajuiDepth {
  /// A força da perspectiva: o termo (3, 2) da matriz de transformação.
  ///
  /// Equivale a olhar a tela a uns 830 px lógicos de distância: um cartão de
  /// 300 px girado 30° encolhe uns 8% na borda que se afasta. Mais forte que
  /// isso, o texto deforma; mais fraco, o giro parece achatado.
  static const double perspective = 0.0012;

  /// A faixa da borda em que a rolagem curva, como fração da altura da tela.
  /// Fora dela, todo item inteiro à vista fica plano — é lá que se lê.
  static const double edgeZone = 0.32;

  /// O quanto um item curva ao entrar ou sair pela borda da rolagem: uns 24°.
  static const double drumTilt = 0.42;

  /// O giro de um vizinho no carrossel: uns 29°, o bastante para mostrar a
  /// face sem esconder o que está escrito nela.
  static const double carouselTurn = 0.5;

  /// O desfoque de onde a entrada cinematográfica parte, em sigma. Só no
  /// nível `full`: desfoque é o efeito mais caro que a tela tem.
  static const double arrivalBlur = 8;
}
