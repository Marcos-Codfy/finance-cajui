import 'package:flutter/animation.dart';

/// Curvas de animação. O caráter da marca é "macio, próximo, natural": por
/// isso a curva padrão de resposta é uma mola, e nenhuma animação é linear.
abstract final class CajuiCurves {
  /// Mola com leve ultrapassagem: toque em botão, cartão, chip.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Desaceleração suave: o que entra na tela.
  static const Curve enter = Cubic(0.2, 0, 0, 1);

  /// Aceleração: o que sai. Sai mais rápido do que entrou.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Ida e volta equilibrada: mudança de valor, troca de cor.
  static const Curve standard = Cubic(0.4, 0, 0.2, 1);

  /// Chegada de câmera: sai rápido, freia, passa uns 3% do destino e volta.
  ///
  /// É a curva da entrada cinematográfica e da pilha de carteira que se
  /// abre. A ultrapassagem é menor que a de [spring] de propósito: num
  /// toque, o exagero é resposta; num bloco inteiro chegando, seria tremor.
  static const Curve settle = Cubic(0.16, 1.2, 0.3, 1.04);
}
