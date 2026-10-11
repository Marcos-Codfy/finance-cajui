import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/widgets.dart';

/// Um bloco na [pose].
///
/// A árvore é sempre a mesma — esmaecer por fora, transformação por dentro
/// —, esteja a pose em movimento ou em repouso. Tirar o `Transform` no fim
/// do movimento mudaria a forma da árvore, e a tela que acabou de chegar
/// perderia o estado: a rolagem, o campo digitado. Em repouso a matriz é a
/// identidade, e o `Transform` pinta direto, sem camada.
class CajuiPosed extends StatelessWidget {
  /// Põe [child] na [pose].
  const new({required this.pose, required this.child, super.key});

  /// A pose.
  final SpacePose pose;

  /// O bloco.
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: pose.opacity.clamp(0, 1).toDouble(),
    child: Transform(
      alignment: pose.pivot,
      transform: pose.local,
      child: child,
    ),
  );
}
