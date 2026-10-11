import 'dart:async';

import 'package:design_system/src/motion/cajui_posed.dart';
import 'package:design_system/src/motion/camera_move.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// As abas como faces de uma cena que a câmera rodeia: trocar de aba é a
/// câmera orbitar de uma para a outra, e não um corte (`CameraMove`).
///
/// Faz o papel do `IndexedStack`: as abas ficam todas montadas, com o
/// estado de cada uma — a conversa pela metade, a rolagem do Início. Só a
/// da frente recebe toque; a que sai ainda aparece durante a órbita, mas
/// não responde.
class CajuiOrbitStack extends StatefulWidget {
  /// Mostra a aba [index] de [children].
  const new({required this.index, required this.children, super.key});

  /// A aba à frente.
  final int index;

  /// As abas, na ordem da barra.
  final List<Widget> children;

  @override
  State<CajuiOrbitStack> createState() => _CajuiOrbitStackState();
}

class _CajuiOrbitStackState extends State<CajuiOrbitStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: CajuiDurations.slow,
    value: 1,
  );

  /// A aba que está saindo, enquanto a órbita anda.
  int? _leaving;

  @override
  void didUpdateWidget(CajuiOrbitStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _leaving = oldWidget.index;
    _orbit.duration = motionOf(context) == MotionLevel.reduced
        ? CajuiDurations.reducedFade
        : CajuiDurations.slow;
    unawaited(_orbit.forward(from: 0).whenComplete(_landed));
  }

  void _landed() {
    if (mounted) setState(() => _leaving = null);
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = motionOf(context);
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _orbit,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            for (final (i, child) in widget.children.indexed)
              _face(i, child, box.maxWidth, level),
          ],
        ),
      ),
    );
  }

  /// Cada aba com a mesma forma de árvore o tempo todo — escondida, à
  /// frente ou orbitando —, para nenhuma perder o estado no meio do caminho.
  Widget _face(int index, Widget child, double width, MotionLevel level) {
    final front = index == widget.index;
    final leaving = index == _leaving;
    // Fora de cena, a aba também fica fora do foco, como no IndexedStack:
    // sem isso, o campo da conversa escondida continuava recebendo teclado,
    // e um "enviar" ia parar na aba que ninguém via.
    return KeyedSubtree(
      key: ValueKey(index),
      child: Offstage(
        offstage: !front && !leaving,
        child: ExcludeFocus(
          excluding: !front,
          child: IgnorePointer(
            ignoring: !front,
            child: CajuiPosed(pose: _pose(front, width, level), child: child),
          ),
        ),
      ),
    );
  }

  SpacePose _pose(bool front, double width, MotionLevel level) {
    final leaving = _leaving;
    if (leaving == null) return SpacePose.rest;
    final t = CajuiCurves.standard.transform(_orbit.value);
    final direction = widget.index > leaving ? 1 : -1;
    return front
        ? CameraMove.orbitIn(t, direction, width, level)
        : CameraMove.orbitOut(t, direction, width, level);
  }
}
