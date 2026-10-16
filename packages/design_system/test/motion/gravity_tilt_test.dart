import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a inclinação a partir da gravidade', () {
    test('na pose de repouso — a 40° da mesa — o cartão fica parado', () {
      final tilt = GravityTilt.of(
        x: 0,
        y: 9.81 * math.sin(GravityTilt.restPitch),
        z: 9.81 * math.cos(GravityTilt.restPitch),
      );

      expect(tilt.dx, closeTo(0, 1e-9));
      expect(tilt.dy, closeTo(0, 1e-9));
    });

    test('a borda direita descendo inclina para a direita', () {
      expect(GravityTilt.of(x: -4.9, y: 6, z: 6).dx, greaterThan(0));
      expect(GravityTilt.of(x: 4.9, y: 6, z: 6).dx, lessThan(0));
    });

    test('nunca passa de -1 a 1, nem com o tranco de um movimento', () {
      final tilt = GravityTilt.of(x: -40, y: 0, z: -30);

      expect(tilt.dx, 1);
      expect(tilt.dy.abs(), lessThanOrEqualTo(1));
    });
  });
}
