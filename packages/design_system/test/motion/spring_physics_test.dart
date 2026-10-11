import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/credit_card/card_tilt_motion.dart';
import 'package:design_system/src/components/gauge/water_motion.dart';
import 'package:design_system/src/motion/damped_spring.dart';
import 'package:flutter_test/flutter_test.dart';

/// Avança uma física quadro a quadro, a 60 por segundo, por [seconds]
/// segundos — ou até ela parar. Devolve quanto tempo levou.
double _run(bool Function(double) step, {double seconds = 10}) {
  const frame = 1 / 60;
  var elapsed = 0.0;
  while (elapsed < seconds) {
    elapsed += frame;
    if (!step(frame)) break;
  }
  return elapsed;
}

void main() {
  group('DampedSpring', () {
    test('a mola da água passa do alvo, volta e assenta', () {
      final spring = DampedSpring(CajuiSprings.slosh)..target = 1;
      var peak = 0.0;
      _run((dt) {
        spring.step(dt);
        peak = math.max(peak, spring.value);
        return !spring.isAtRest;
      });

      expect(peak, greaterThan(1.3), reason: 'pouco amortecida: balança');
      expect(spring.isAtRest, isTrue);
      expect(spring.value, 1);
    });

    test('a mola do cartão quase não passa: segue sem tremer', () {
      final spring = DampedSpring(CajuiSprings.tilt)..target = 1;
      var peak = 0.0;
      _run((dt) {
        spring.step(dt);
        peak = math.max(peak, spring.value);
        return !spring.isAtRest;
      });

      expect(peak, lessThan(1.05));
      expect(spring.value, 1);
    });

    test('um quadro longo — o app voltando do fundo — não dá salto', () {
      final spring = DampedSpring(CajuiSprings.slosh)
        ..target = 1
        ..step(30);

      expect(spring.value, lessThan(0.2));
    });
  });

  group('RNF-A11Y-08 WaterMotion', () {
    test('enche até o nível e para sozinha, em menos de 5 s', () {
      final water = WaterMotion()..fillTo(0.6);
      final took = _run(water.step);

      expect(water.isAtRest, isTrue);
      expect(water.level, closeTo(0.6, 0.001));
      expect(took, lessThan(5));
      water.dispose();
    });

    test('a superfície gira ao contrário do aparelho, com limite', () {
      final water = WaterMotion(level: 0.5)..tiltTo(0.2);
      _run(water.step);

      // O aparelho gira para a direita: a água, que fica na horizontal do
      // mundo, gira para a esquerda na tela.
      expect(water.angle, closeTo(-math.asin(0.2), 0.001));

      water.tiltTo(1);
      _run(water.step);
      expect(water.angle, closeTo(-WaterMotion.maxAngle, 0.001));
      water.dispose();
    });

    test('ao parar a mão, a água ainda balança e depois assenta', () {
      final water = WaterMotion(level: 0.5)..tiltTo(0.3);
      _run(water.step, seconds: 0.15);

      expect(water.ripple, greaterThan(0));
      expect(water.isAtRest, isFalse);
      _run(water.step);
      expect(water.isAtRest, isTrue);
      water.dispose();
    });

    test('valor que não é número não deixa a água balançando para sempre', () {
      final water = WaterMotion()
        ..fillTo(double.nan)
        ..tiltTo(double.infinity);
      _run(water.step);

      expect(water.isAtRest, isTrue);
      expect(water.level, 0);
      water.dispose();
    });

    test('a versão parada: nível certo, superfície reta, sem onda', () {
      final water = WaterMotion()
        ..fillTo(0.4)
        ..tiltTo(0.5)
        ..settle();

      expect(water.level, 0.4);
      expect(water.angle, 0);
      expect(water.ripple, 0);
      expect(water.isAtRest, isTrue);
      water.dispose();
    });
  });

  group('CardTiltMotion', () {
    test('o dedo vence o sensor e, ao soltar, o sensor volta a mandar', () {
      final card = CardTiltMotion()
        ..sense(const Offset(0.4, 0))
        ..hold(const Offset(-1, 1));
      _run(card.step);

      expect(card.tilt.dx, closeTo(-1, 0.001));
      expect(card.tilt.dy, closeTo(1, 0.001));

      card.release();
      _run(card.step);
      expect(card.tilt.dx, closeTo(0.4, 0.001));
      expect(card.tilt.dy, closeTo(0, 0.001));
      card.dispose();
    });

    test('leitura que não é número vira repouso', () {
      final card = CardTiltMotion()..sense(const Offset(double.nan, 0.5));
      _run(card.step);

      expect(card.isAtRest, isTrue);
      expect(card.tilt, Offset.zero);
      card.dispose();
    });

    test('leitura fora da faixa é limitada a -1 e 1', () {
      final card = CardTiltMotion()..sense(const Offset(3, -7));
      _run(card.step);

      expect(card.tilt, const Offset(1, -1));
      card.dispose();
    });
  });
}
