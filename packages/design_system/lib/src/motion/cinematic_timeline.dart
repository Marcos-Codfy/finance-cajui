import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/stagger.dart';
import 'package:flutter/widgets.dart';

/// O relógio de uma entrada cinematográfica, entregue às tomadas
/// (`CajuiCinematicShot`) e às pilhas de carteira que estão abaixo dela.
///
/// Um relógio só para a tela inteira, e não um por bloco: as tomadas ficam
/// em fase entre si, e a varredura de luz passa no ritmo delas.
class CinematicTimeline extends InheritedWidget {
  /// Publica [progress], de 0 a 1, no nível de movimento [motion].
  const new({
    required this.progress,
    required this.motion,
    required super.child,
    super.key,
  });

  /// Quanto da entrada já passou, de 0 a 1.
  final Animation<double> progress;

  /// O nível de movimento em vigor.
  final MotionLevel motion;

  /// O relógio mais próximo acima de [context], se houver.
  static CinematicTimeline? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CinematicTimeline>();

  /// O quanto da própria chegada a tomada [index] já fez, de 0 a 1. No
  /// `reduced` não há cascata: todas esmaecem juntas.
  double shotProgress(int index) => motion == MotionLevel.reduced
      ? progress.value
      : staggered(progress.value, index);

  @override
  bool updateShouldNotify(CinematicTimeline oldWidget) =>
      progress != oldWidget.progress || motion != oldWidget.motion;
}
