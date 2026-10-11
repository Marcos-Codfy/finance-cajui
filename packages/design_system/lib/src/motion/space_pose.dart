import 'package:design_system/src/tokens/primitives/cajui_depth.dart';
import 'package:flutter/widgets.dart';

/// Onde um bloco está no espaço: quanto gira, quanto encolhe, quanto anda e
/// quanto apaga.
///
/// Todos os efeitos de profundidade do design system descrevem o quadro
/// atual com isto, e só no fim viram matriz. Assim a conta de cada efeito é
/// uma função pura — testável sem montar tela —, e todos passam pela mesma
/// lente (`CajuiDepth.perspective`).
@immutable
class SpacePose {
  /// Cria a pose. Os padrões são o bloco parado, plano e inteiro.
  const new({
    this.tilt = 0,
    this.turn = 0,
    this.scale = 1,
    this.shift = Offset.zero,
    this.opacity = 1,
    this.pivot = Alignment.center,
  });

  /// O bloco em repouso: sem giro, sem escala, sem deslocamento.
  static const rest = SpacePose();

  /// O giro em torno do eixo horizontal, em radianos. Positivo: a borda de
  /// baixo se afasta de quem olha.
  final double tilt;

  /// O giro em torno do eixo vertical, em radianos. Positivo: a borda da
  /// direita se afasta de quem olha.
  final double turn;

  /// A escala, em torno de [pivot].
  final double scale;

  /// O deslocamento, em pixels lógicos, depois do giro.
  final Offset shift;

  /// A opacidade, de 0 a 1.
  final double opacity;

  /// O ponto que fica parado no giro e na escala.
  final Alignment pivot;

  /// Se a pose não muda nada da geometria: é quando a transformação pode
  /// sair de cena e o quadro fica de graça.
  bool get isFlat =>
      tilt == 0 && turn == 0 && scale == 1 && shift == Offset.zero;

  /// A opacidade em 0–255, como a camada de opacidade a pede.
  int get alpha => (opacity.clamp(0, 1) * 255).round();

  /// A matriz em torno de [pivot], para o `Transform` que recebe o ponto de
  /// giro como alinhamento.
  ///
  /// O deslocamento entra antes da lente: o centro da perspectiva fica onde
  /// o bloco estava antes de andar. No carrossel, isso põe a câmera no meio
  /// do palco, e os vizinhos fogem para o mesmo ponto — uma cena só, e não
  /// cada cartão com a sua câmera.
  ///
  /// Sem giro, a lente fica de fora: a matriz de um bloco em repouso é a
  /// identidade exata, e o `Transform` pinta direto, sem camada.
  Matrix4 get local {
    final matrix = Matrix4.translationValues(shift.dx, shift.dy, 0);
    if (tilt != 0 || turn != 0) {
      matrix
        ..setEntry(3, 2, CajuiDepth.perspective)
        ..rotateX(tilt)
        ..rotateY(-turn);
    }
    if (scale != 1) matrix.scaleByDouble(scale, scale, 1, 1);
    return matrix;
  }

  /// A matriz completa para um bloco de tamanho [size], com o ponto de giro
  /// já resolvido: é a que a pintura e o toque usam.
  Matrix4 matrix(Size size) {
    final origin = pivot.alongSize(size);
    return Matrix4.translationValues(origin.dx, origin.dy, 0)
      ..multiply(local)
      ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
  }
}
