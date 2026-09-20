/// O tamanho de um botão. O alvo tocável tem sempre 48 dp ou mais, qualquer
/// que seja o tamanho do desenho.
enum CajuiButtonSize {
  /// 52 de altura: o botão de ação de uma tela.
  regular(height: 52, horizontalPadding: 24),

  /// 40 de altura: dentro de cartão, aviso e lista.
  compact(height: 40, horizontalPadding: 16);

  new({required this.height, required this.horizontalPadding});

  /// A altura do desenho.
  final double height;

  /// O respiro à esquerda e à direita do rótulo.
  final double horizontalPadding;
}
