import 'package:design_system/src/components/depth/drum_pose.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/motion/render_viewport_pose.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/widgets.dart';

/// Um item da `CajuiDepthScroll`: curva na borda da tela conforme rola.
///
/// Lê a rolagem mais próxima acima dele. No `full`, curva e esmaece; no
/// `lite`, só curva — esmaecer custa uma camada por item na borda —; no
/// `reduced`, fica plano e nem chega a ouvir a rolagem.
class DepthItem extends SingleChildRenderObjectWidget {
  /// Cria o item em volta de [child]. [geometry] avisa de mudança de
  /// tamanho da lista sem rolagem.
  const new({required super.child, this.geometry, super.key});

  /// O aviso de que a geometria da lista mudou.
  final Listenable? geometry;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final motion = motionOf(context);
    return _RenderDepthItem(
      position: Scrollable.maybeOf(context)?.position,
      geometry: geometry,
      motion: motion,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final motion = motionOf(context);
    (renderObject as _RenderDepthItem)
      ..motion = motion
      ..position = Scrollable.maybeOf(context)?.position
      ..geometry = geometry;
  }
}

class _RenderDepthItem extends RenderViewportPose {
  new({required MotionLevel motion, super.position, super.geometry})
    : _motion = motion,
      super(active: motion != MotionLevel.reduced);

  MotionLevel _motion;

  MotionLevel get motion => _motion;
  set motion(MotionLevel value) {
    if (value == _motion) return;
    _motion = value;
    active = value != MotionLevel.reduced;
    markNeedsPaint();
  }

  @override
  SpacePose poseFor(double top, double bottom, double extent) => DrumPose.of(
    top: top,
    bottom: bottom,
    extent: extent,
    fades: _motion.allowsDecorativeMotion,
  );
}
