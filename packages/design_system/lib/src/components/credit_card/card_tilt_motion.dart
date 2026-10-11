import 'dart:ui' show Offset;

import 'package:design_system/src/motion/damped_spring.dart';
import 'package:design_system/src/tokens/primitives/cajui_springs.dart';
import 'package:flutter/foundation.dart';

/// Para onde o cartão está inclinado, seguindo o sensor ou o dedo.
///
/// O dedo vence o sensor enquanto encosta: quem arrasta o cartão quer ver o
/// brilho andar sob a mão. Ao soltar, o cartão volta — com mola — para onde
/// o celular manda.
class CardTiltMotion extends ChangeNotifier {
  final DampedSpring _x = DampedSpring(CajuiSprings.tilt);
  final DampedSpring _y = DampedSpring(CajuiSprings.tilt);
  Offset _sensor = Offset.zero;
  Offset? _hand;

  /// A inclinação atual, de -1 a 1 em cada eixo.
  Offset get tilt => Offset(_x.value, _y.value);

  /// Se o cartão chegou aonde devia e parou.
  bool get isAtRest => _x.isAtRest && _y.isAtRest;

  /// Leitura que não é número vira repouso: com ela, a mola nunca pararia.
  static Offset _clamp(Offset value) {
    if (!value.isFinite) return Offset.zero;
    return Offset(
      value.dx.clamp(-1, 1).toDouble(),
      value.dy.clamp(-1, 1).toDouble(),
    );
  }

  /// Uma leitura nova do sensor (`CajuiTilt`).
  void sense(Offset value) {
    _sensor = _clamp(value);
    _aim();
  }

  /// O dedo encostou ou se moveu: [value] é a posição do dedo, de -1 a 1.
  void hold(Offset value) {
    _hand = _clamp(value);
    _aim();
  }

  /// O dedo saiu do cartão.
  void release() {
    _hand = null;
    _aim();
  }

  void _aim() {
    final target = _hand ?? _sensor;
    _x.target = target.dx;
    _y.target = target.dy;
  }

  /// Avança [seconds] segundos. Devolve se ainda há movimento.
  bool step(double seconds) {
    _x.step(seconds);
    _y.step(seconds);
    notifyListeners();
    return !isAtRest;
  }

  /// O cartão reto e parado: a versão do movimento reduzido.
  void settle() {
    _hand = null;
    _sensor = Offset.zero;
    _x.jumpTo(0);
    _y.jumpTo(0);
    notifyListeners();
  }
}
