import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/motion/render_viewport_pose.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/widgets.dart';

/// Uma camada que anda em outra velocidade quando a tela rola: a paralaxe.
///
/// Com [factor] positivo, a camada fica para trás — sobe mais devagar que o
/// resto, como o que está longe numa janela de trem. Com negativo, adianta-se,
/// como o que está perto. No centro da tela ela está exatamente onde o
/// layout a pôs; o deslocamento cresce com a distância ao centro.
///
/// Profundidade com propósito: serve para separar o que é fundo do que é
/// dado — a ilustração atrás do número, nunca o número. É enfeite, e no
/// movimento reduzido fica parada (RNF-A11Y-07).
class CajuiParallax extends SingleChildRenderObjectWidget {
  /// Põe [child] numa camada de paralaxe com força [factor].
  const new({required super.child, this.factor = 0.15, super.key})
    : assert(factor > -1 && factor < 1, 'Paralaxe é fração da rolagem.');

  /// A fração da distância ao centro da tela que a camada fica para trás.
  /// Entre 0,1 e 0,3 já se percebe; acima disso, o bloco parece solto.
  final double factor;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderParallax(
    factor: factor,
    position: Scrollable.maybeOf(context)?.position,
    active: motionOf(context) != MotionLevel.reduced,
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderParallax)
      ..factor = factor
      ..position = Scrollable.maybeOf(context)?.position
      ..active = motionOf(context) != MotionLevel.reduced;
  }
}

class _RenderParallax extends RenderViewportPose {
  new({required this._factor, super.position, super.active});

  double _factor;

  double get factor => _factor;
  set factor(double value) {
    if (value == _factor) return;
    _factor = value;
    markNeedsPaint();
  }

  @override
  SpacePose poseFor(double top, double bottom, double extent) {
    final fromCenter = (top + bottom) / 2 - extent / 2;
    return SpacePose(shift: Offset(0, -_factor * fromCenter));
  }
}
