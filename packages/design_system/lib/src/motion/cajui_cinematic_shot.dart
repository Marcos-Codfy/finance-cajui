import 'dart:ui' show ImageFilter;

import 'package:design_system/src/motion/arrival_pose.dart';
import 'package:design_system/src/motion/cinematic_timeline.dart';
import 'package:flutter/widgets.dart';

/// Uma tomada da entrada cinematográfica: um bloco que chega da
/// profundidade quando a `CajuiCinematicEntrance` acima dele começa.
///
/// [index] é a ordem de chegada. Sem entrada acima, a tomada não faz nada —
/// o bloco simplesmente está lá. Bloco montado depois que a entrada acabou
/// (rolado para a tela mais tarde) também já chega pronto: a câmera anda uma
/// vez, ao abrir, e não a cada rolagem.
///
/// O leitor de tela encontra o bloco desde o primeiro quadro, mesmo ainda
/// transparente: a entrada é para o olho, e não atrasa quem ouve.
class CajuiCinematicShot extends StatelessWidget {
  /// Marca [child] como a tomada número [index].
  const new({required this.child, this.index = 0, super.key});

  /// O bloco.
  final Widget child;

  /// A ordem de chegada, a partir de 0.
  final int index;

  /// Abaixo deste sigma o desfoque não se vê, e sai de cena: filtro ligado
  /// custa uma camada inteira por bloco.
  static const double _sharp = 0.05;

  @override
  Widget build(BuildContext context) {
    final timeline = CinematicTimeline.maybeOf(context);
    if (timeline == null) return child;
    return AnimatedBuilder(
      animation: timeline.progress,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final (pose, blur) = ArrivalPose.of(
          timeline.shotProgress(index),
          motion: timeline.motion,
        );
        // A matriz por fora, para o toque passar por ela primeiro.
        return Transform(
          alignment: pose.pivot,
          transform: pose.local,
          child: ImageFiltered(
            enabled: blur > _sharp,
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Opacity(
              opacity: pose.opacity,
              alwaysIncludeSemantics: true,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
