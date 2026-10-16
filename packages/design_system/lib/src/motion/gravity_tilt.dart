import 'dart:math' as math;
import 'dart:ui' show Offset;

/// A conta que transforma a gravidade lida pelo acelerômetro na inclinação
/// do `CajuiTilt`. O design system não lê sensor; só faz a conta, para o app
/// (sensor do Android) e a gallery (sensor do navegador do celular) moverem
/// o cartão do mesmo jeito.
abstract final class GravityTilt {
  /// A pose de repouso: o celular na mão costuma ficar a uns 40° da mesa.
  static const double restPitch = 40 * math.pi / 180;

  static const double _gravity = 9.81;

  /// A inclinação para a gravidade [x], [y] e [z], em m/s². `dx` é o seno do
  /// ângulo de lado; `dy`, o de frente descontada a pose de repouso.
  static Offset of({required double x, required double y, required double z}) {
    final side = (-x / _gravity).clamp(-1, 1).toDouble();
    final pitch = math.atan2(y, z);
    final front = math.sin(pitch - restPitch).clamp(-1, 1).toDouble();
    return Offset(side, front);
  }
}
