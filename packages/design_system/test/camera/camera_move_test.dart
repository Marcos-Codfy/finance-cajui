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

    test('a tela de trás recua e some no primeiro terço da troca', () {
      final behind = CameraMove.receding(CameraMove.leaveBy, MotionLevel.full);

      expect(behind.scale, CameraMove.recedeScale);
      expect(behind.opacity, 0);
    });

    test('a passagem: em nenhum ponto do relógio as duas telas aparecem '
        'juntas, em nenhum nível de movimento', () {
      for (final level in MotionLevel.values) {
        for (var step = 0; step <= 100; step++) {
          final clock = step / 100;
          final behind = CameraMove.receding(clock, level).opacity;
          final ahead = CameraMove.arriving(clock, level).opacity;
          final aside = CameraMove.orbitOut(clock, 1, 400, level).opacity;
          final front = CameraMove.orbitIn(clock, 1, 400, level).opacity;

          expect(behind < ahead ? behind : ahead, lessThan(0.05));
          expect(aside < front ? aside : front, lessThan(0.05));
        }
      }
    });

    test('a tela nova faz o caminho todo depois de começar a aparecer: '
        'invisível, ela ainda não andou', () {
      final hidden = CameraMove.arriving(
        CameraMove.arriveFrom,
        MotionLevel.full,
      );

      expect(hidden.opacity, 0);
      expect(hidden.tilt, CameraMove.arrivalTilt);
      expect(hidden.scale, CameraMove.arrivalScale);
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
