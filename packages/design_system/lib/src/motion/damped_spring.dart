import 'dart:math' as math;

import 'package:flutter/physics.dart';

/// Uma mola que persegue um alvo que muda a qualquer momento.
///
/// A `SpringSimulation` do Flutter resolve uma mola com começo e fim fixos.
/// Aqui o alvo é o celular inclinando — muda a cada leitura do sensor —, então
/// a mola é integrada passo a passo, quadro a quadro, e herda a velocidade de
/// um alvo para o seguinte. É essa herança que faz a água balançar quando a
/// mão para de repente.
class DampedSpring {
  /// Cria a mola com a física [description], parada em [value].
  new(this.description, {double value = 0, this.tolerance = 0.001})
    : _value = value,
      target = value;

  /// Quanto a mola puxa e quanto freia: um token de `CajuiSprings`.
  final SpringDescription description;

  /// Abaixo desta distância e desta velocidade, a mola está parada.
  final double tolerance;

  /// Para onde a mola está indo.
  double target;

  double _value;
  double _velocity = 0;

  /// Passo máximo de integração. Abaixo de 1/240 s a mola mais dura do
  /// projeto continua estável com o método de Euler semi-implícito.
  static const double _substep = 1 / 240;

  /// Um quadro nunca vale mais que isto: depois de o app voltar do fundo, a
  /// mola não dá um salto de segundos de uma vez.
  static const double _maxFrame = 1 / 20;

  /// Onde a mola está.
  double get value => _value;

  /// A velocidade, em unidades por segundo.
  double get velocity => _velocity;

  /// Se a mola chegou ao alvo e parou: é quando o quadro pode deixar de ser
  /// pedido, e a bateria agradece.
  bool get isAtRest =>
      (_value - target).abs() < tolerance && _velocity.abs() < tolerance;

  /// Leva a mola direto a [value], parada. Serve ao movimento reduzido.
  void jumpTo(double value) {
    _value = value;
    target = value;
    _velocity = 0;
  }

  /// Dá um empurrão: soma [velocity] à velocidade atual.
  void kick(double velocity) => _velocity += velocity;

  /// Avança a mola [seconds] segundos.
  void step(double seconds) {
    var remaining = math.min(seconds, _maxFrame);
    while (remaining > 0) {
      final dt = math.min(remaining, _substep);
      final pull = -description.stiffness * (_value - target);
      final brake = -description.damping * _velocity;
      _velocity += (pull + brake) / description.mass * dt;
      _value += _velocity * dt;
      remaining -= dt;
    }
    if (isAtRest) jumpTo(target);
  }
}
