import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/credit_card/card_tilt_motion.dart';
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
