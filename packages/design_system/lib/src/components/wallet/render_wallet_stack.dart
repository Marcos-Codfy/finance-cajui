import 'dart:math' as math;

import 'package:design_system/src/components/wallet/wallet_parent_data.dart';
import 'package:design_system/src/components/wallet/wallet_pose.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/motion/stagger.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A pilha de carteira: mede os cartões como uma coluna e os pinta onde a
/// `WalletPose` manda.
///
/// O layout é sempre o da coluna aberta — a altura não muda quando a pilha
/// se fecha ou se abre, e a rolagem não pula. Todo o movimento é pintura:
/// rolar, puxar e o maço se abrindo só trocam matrizes (RNF-PERF-01).
class RenderWalletStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, WalletParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, WalletParentData> {
  /// Cria a pilha com [gap] entre os cartões.
  new({
    required this._gap,
    required this._deal,
    required this._motion,
    this._position,
  });

  double _gap;
  Animation<double> _deal;
  MotionLevel _motion;
  ScrollPosition? _position;

  /// O espaço entre um cartão e o seguinte, com a pilha aberta.
  double get gap => _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  /// O relógio do maço se abrindo, de 0 a 1.
  Animation<double> get deal => _deal;
  set deal(Animation<double> value) {
    if (value == _deal) return;
    if (attached) _deal.removeListener(_moved);
    _deal = value;
    if (attached) _deal.addListener(_moved);
    _moved();
  }

  /// O nível de movimento. No `reduced`, é uma coluna parada.
  MotionLevel get motion => _motion;
  set motion(MotionLevel value) {
    if (value == _motion) return;
    _motion = value;
    markNeedsCompositingBitsUpdate();
    _moved();
  }

  /// A rolagem em que a pilha está.
  ScrollPosition? get position => _position;
  set position(ScrollPosition? value) {
    if (value == _position) return;
    if (attached) _position?.removeListener(_moved);
    _position = value;
    if (attached) _position?.addListener(_moved);
    _moved();
  }

  void _moved() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _deal.addListener(_moved);
    _position?.addListener(_moved);
  }

  @override
  void detach() {
    _deal.removeListener(_moved);
    _position?.removeListener(_moved);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! WalletParentData) {
      child.parentData = WalletParentData();
    }
  }

  @override
  bool get alwaysNeedsCompositing =>
      firstChild != null && _motion != MotionLevel.reduced;

  Size _column(BoxConstraints constraints, Size Function(RenderBox) measure) {
    var height = 0.0;
    var width = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final size = measure(child);
      width = math.max(width, size.width);
      height += size.height + (child == firstChild ? 0 : _gap);
    }
    final across = constraints.hasBoundedWidth ? constraints.maxWidth : width;
    return constraints.constrain(Size(across, height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _column(
    constraints,
    (child) =>
        child.getDryLayout(BoxConstraints(maxWidth: constraints.maxWidth)),
  );

  @override
  void performLayout() {
    final inner = BoxConstraints(maxWidth: constraints.maxWidth);
    size = _column(constraints, (child) {
      child.layout(inner, parentUsesSize: true);
      return child.size;
    });
    var top = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      (child.parentData! as WalletParentData)
        ..offset = Offset((size.width - child.size.width) / 2, top)
        ..transform = null;
      top += child.size.height + _gap;
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) => _stacked(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _stacked(width);

  double _stacked(double width) {
    var total = math.max(0, childCount - 1) * _gap;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      total += child.getMaxIntrinsicHeight(width);
    }
    return total;
  }

  /// O alto da tela nas coordenadas da pilha, e o puxão além do topo. Fora
  /// de uma rolagem vertical, não há alto de tela a seguir.
  ({double? top, double pull}) _viewport() {
    final viewport = RenderAbstractViewport.maybeOf(parent);
    if (viewport is! RenderViewportBase || viewport.axis != Axis.vertical) {
      return (top: null, pull: 0);
    }
    final top = MatrixUtils.transformPoint(
      getTransformTo(viewport),
      Offset.zero,
    );
    final scroll = _position;
    final measured =
        scroll != null && scroll.hasPixels && scroll.hasContentDimensions;
    final pull = measured
        ? math.max<double>(0, scroll.minScrollExtent - scroll.pixels)
        : 0.0;
    return (top: -top.dy, pull: pull);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final active = _motion != MotionLevel.reduced;
    final view = active ? _viewport() : (top: null, pull: 0.0);
    final last = lastChild?.parentData as WalletParentData?;
    var index = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as WalletParentData;
      final slot = (
        index: index,
        count: childCount,
        top: data.offset.dy,
        height: child.size.height,
        lastTop: last?.offset.dy ?? 0.0,
        gap: _gap,
      );
      final pose = active
          ? WalletPose.of(
              slot,
              deal: staggered(_deal.value, childCount - 1 - index),
              viewportTop: view.top,
              pull: view.pull,
              fades: _motion.allowsDecorativeMotion,
            )
          : SpacePose.rest;
      _paintCard(context, offset, child, pose);
      index++;
    }
  }

  void _paintCard(
    PaintingContext context,
    Offset offset,
    RenderBox card,
    SpacePose pose,
  ) {
    final data = card.parentData! as WalletParentData;
    final matrix = Matrix4.translationValues(data.offset.dx, data.offset.dy, 0)
      ..multiply(pose.matrix(card.size));
    data.transform = matrix;
    if (pose.isFlat && pose.alpha == 255) {
      data.moved.layer = null;
      data.faded.layer = null;
      context.paintChild(card, offset + data.offset);
      return;
    }
    data.moved.layer = context.pushTransform(
      needsCompositing,
      offset,
      matrix,
      (context, offset) => _paintFaded(context, offset, card, pose.alpha),
      oldLayer: data.moved.layer,
    );
  }

  void _paintFaded(
    PaintingContext context,
    Offset offset,
    RenderBox card,
    int alpha,
  ) {
    final data = card.parentData! as WalletParentData;
    if (alpha == 255) {
      data.faded.layer = null;
      context.paintChild(card, offset);
      return;
    }
    data.faded.layer = context.pushOpacity(
      offset,
      alpha,
      (context, offset) => context.paintChild(card, offset),
      oldLayer: data.faded.layer,
    );
  }

  /// O de cima primeiro: na pilha, o cartão que cobre os outros é o último.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (var child = lastChild; child != null; child = childBefore(child)) {
      final card = child;
      final hit = result.addWithPaintTransform(
        transform: (card.parentData! as WalletParentData).effective,
        position: position,
        hitTest: (result, local) => card.hitTest(result, position: local),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply((child.parentData! as WalletParentData).effective);
  }
}
