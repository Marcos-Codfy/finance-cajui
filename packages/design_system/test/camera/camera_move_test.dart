import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraMove · a câmera entre telas', () {
    test('a tela nova chega de longe — deitada, menor, abaixo — e termina '
        'no lugar, plana', () {
      final start = CameraMove.arriving(0, MotionLevel.full);
      final end = CameraMove.arriving(1, MotionLevel.full);

      expect(start.tilt, CameraMove.arrivalTilt);
      expect(start.scale, CameraMove.arrivalScale);
      expect(start.shift.dy, CameraMove.arrivalRise);
      expect(end.isFlat, isTrue);
      expect(end.opacity, 1);
    });

    test('a tela de trás recua e apaga enquanto a nova chega', () {
      final behind = CameraMove.receding(1, MotionLevel.full);

      expect(behind.scale, CameraMove.recedeScale);
      expect(behind.opacity, lessThan(1));
    });

    test('a órbita: a aba que chega vem do lado da ida, girada, e a que sai '
        'vai para o lado oposto', () {
      final arriving = CameraMove.orbitIn(0, 1, 400, MotionLevel.full);
      final leaving = CameraMove.orbitOut(1, 1, 400, MotionLevel.full);

      expect(arriving.turn, CameraMove.orbitTurn);
      expect(arriving.shift.dx, 400 * CameraMove.orbitTravel);
      expect(leaving.turn, -CameraMove.orbitTurn);
      expect(leaving.shift.dx, -400 * CameraMove.orbitTravel);
      expect(CameraMove.orbitIn(1, 1, 400, MotionLevel.full).isFlat, isTrue);
    });

    test(
      'RNF-A11Y-07 · movimento reduzido: nada gira nem anda, só esmaece',
      () {
        for (final pose in [
          CameraMove.arriving(0.3, MotionLevel.reduced),
          CameraMove.receding(0.6, MotionLevel.reduced),
          CameraMove.orbitIn(0.2, -1, 400, MotionLevel.reduced),
          CameraMove.orbitOut(0.7, -1, 400, MotionLevel.reduced),
        ]) {
          expect(pose.isFlat, isTrue);
        }
      },
    );

    test('nível leve: desliza, mas não gira', () {
      final pose = CameraMove.arriving(0.5, MotionLevel.lite);

      expect(pose.tilt, 0);
      expect(pose.shift, isNot(Offset.zero));
    });
  });
}
