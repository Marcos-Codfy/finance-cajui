import 'dart:math' as math;

import 'package:design_system/src/motion/damped_spring.dart';
import 'package:design_system/src/tokens/primitives/cajui_springs.dart';
import 'package:flutter/foundation.dart';

/// A física da água no pote: o nível, a inclinação da superfície e a marola.
///
/// Fica separada do desenho para poder ser testada sem tela: dá para afirmar
/// que a água ultrapassa e volta, e que assenta, só avançando o tempo.
///
/// Três movimentos somados:
/// - o **nível** sobe ou baixa até a fração pedida, com uma mola macia;
/// - a **superfície** fica na horizontal do mundo: se o celular gira para a
///   direita, ela gira para a esquerda na tela, numa mola pouco amortecida —
///   é o balanço;
/// - a **marola** é uma onda que corre na superfície, nasce de cada mudança
///   e do próprio balanço, e morre sozinha.
class WaterMotion extends ChangeNotifier {
  /// Cria a água parada no nível [level], de 0 a 1.
  new({double level = 0})
    : _level = DampedSpring(CajuiSprings.level, value: _fraction(level));

  final DampedSpring _level;
  final DampedSpring _surface = DampedSpring(CajuiSprings.slosh);
  double _ripple = 0;
  double _phase = 0;

  /// O quanto a superfície pode girar: 0,4 rad, uns 23°. Mais que isso, num
  /// pote baixinho, a água pareceria escorrer pela parede.
  static const double maxAngle = 0.4;

  /// A marola mais alta, em fração da altura do pote.
  static const double maxRipple = 0.05;

  /// A marola perde 85% da altura por segundo.
  static const double _rippleDecay = 1.9;

  /// A onda dá 1,3 volta por segundo: lenta, de água, não de vibração.
  static const double _rippleSpeed = 2 * math.pi * 1.3;

  /// Abaixo disto a marola é invisível e conta como parada.
  static const double _still = 0.0005;

  /// Valor que não é número — uma divisão por zero no caminho, uma leitura
  /// ruim do sensor — vira zero aqui. Sem isso a mola nunca chegaria ao
  /// alvo, e o relógio de quadros nunca dormiria.
  static double _finite(double value, double lower, double upper) =>
      value.isFinite ? value.clamp(lower, upper).toDouble() : 0;

  static double _fraction(double value) => _finite(value, 0, 1);

  /// O nível, de 0 (vazio) a 1 (cheio). Pode passar um pouco na mola.
  double get level => _level.value.clamp(0, 1.05).toDouble();

  /// A inclinação da superfície na tela, em radianos. Positivo é horário.
  double get angle => _surface.value;

  /// A altura da onda, em fração da altura do pote.
  double get ripple {
    final sway = _surface.velocity.abs() * 0.02;
    return math.min(maxRipple, _ripple + sway);
  }

  /// Onde a onda está no seu ciclo, em radianos.
  double get phase => _phase;

  /// Se nada mais se mexe: o relógio de quadros pode dormir.
  bool get isAtRest => _level.isAtRest && _surface.isAtRest && _ripple == 0;

  /// Leva o nível a [fraction] e levanta uma marola do tamanho da mudança.
  void fillTo(double fraction) {
    final next = _fraction(fraction);
    final change = (next - _level.target).abs();
    if (change == 0) return;
    _level.target = next;
    _ripple = math.min(maxRipple, _ripple + 0.012 + change * 0.25);
  }

  /// Recebe o lado da inclinação do aparelho (`CajuiTilt.dx`, de -1 a 1).
  void tiltTo(double side) {
    final device = math.asin(_finite(side, -1, 1));
    _surface.target = (-device).clamp(-maxAngle, maxAngle);
  }

  /// Avança [seconds] segundos. Devolve se ainda há movimento.
  bool step(double seconds) {
    _level.step(seconds);
    _surface.step(seconds);
    _ripple *= math.exp(-_rippleDecay * seconds);
    if (_ripple < _still) _ripple = 0;
    _phase = (_phase + _rippleSpeed * seconds) % (2 * math.pi);
    notifyListeners();
    return !isAtRest;
  }

  /// Põe tudo parado no lugar: nível certo, superfície reta, sem onda. É a
  /// versão do movimento reduzido.
  void settle() {
    _level.jumpTo(_level.target);
    _surface.jumpTo(0);
    _ripple = 0;
    notifyListeners();
  }
}
