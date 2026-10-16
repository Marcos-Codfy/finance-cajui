import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('o filtro que faz o cartão seguir o celular', () {
    test('a primeira leitura é a pose: o cartão nasce reto, em qualquer '
        'ângulo que a pessoa segure', () {
      expect(TiltFilter().next(const Offset(0.4, -0.3)), Offset.zero);
    });

    test('inclinar responde com ganho: 0,17 de leitura (uns 10°) passa '
        'de 0,3 no cartão em menos de meio segundo', () {
      final filter = TiltFilter()..next(Offset.zero);
      var tilt = Offset.zero;
      for (var sample = 0; sample < 7; sample++) {
        tilt = filter.next(const Offset(0.17, 0));
      }

      expect(tilt.dx, greaterThan(0.3));
    });

    test('parado na pose nova, o cartão volta ao centro sozinho', () {
      final filter = TiltFilter()..next(Offset.zero);
      var tilt = Offset.zero;
      for (var sample = 0; sample < 300; sample++) {
        tilt = filter.next(const Offset(0.5, 0.2));
      }

      expect(tilt.dx.abs(), lessThan(0.05));
      expect(tilt.dy.abs(), lessThan(0.05));
    });

    test('o tranco nunca passa de -1 a 1', () {
      final filter = TiltFilter()..next(Offset.zero);
      final tilt = filter.next(const Offset(1, -1));

      expect(tilt.dx, lessThanOrEqualTo(1));
      expect(tilt.dy, greaterThanOrEqualTo(-1));
    });
  });
}
