import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A base dos efeitos que dependem de onde o bloco está na tela que rola.
///
/// A conta é feita **na pintura**, e não na montagem nem no layout: quando a
/// lista rola, só a matriz muda. Nada é reconstruído, nada é medido de novo,
/// e o filho — que fica num `RepaintBoundary` — é reaproveitado como está.
/// É o que deixa o efeito caber nos 16 ms do quadro (RNF-PERF-01).
///
/// A posição é lida já com o layout do quadro pronto, o que tira o atraso de
/// um quadro que ler a posição na montagem teria. Quem herda só diz qual
/// pose cabe a cada lugar ([poseFor]); toque, leitor de tela e camadas
/// ficam aqui, iguais para todos.
abstract class RenderViewportPose extends RenderProxyBox {
  /// Cria o efeito, ouvindo [position] e, se dado, [geometry].
  new({this._position, this._geometry, this._active = true});

  ScrollPosition? _position;
  Listenable? _geometry;
  bool _active;
  Matrix4? _transform;
  final LayerHandle<OpacityLayer> _fade = LayerHandle();

  /// A rolagem que move o bloco.
  ScrollPosition? get position => _position;
  set position(ScrollPosition? value) {
    if (value == _position) return;
    if (attached) _position?.removeListener(_moved);
    _position = value;
    if (attached) _position?.addListener(_moved);
    _moved();
  }

  /// Um aviso extra de que a geometria mudou sem rolagem: a lista cresceu,
  /// a tela girou. Sem ele, a pose ficaria velha até o próximo arrasto.
  Listenable? get geometry => _geometry;
  set geometry(Listenable? value) {
    if (value == _geometry) return;
    if (attached) _geometry?.removeListener(_moved);
    _geometry = value;
    if (attached) _geometry?.addListener(_moved);
    _moved();
  }

  /// Se o efeito está ligado. Desligado, o bloco é pintado como está — é o
  /// movimento reduzido.
  bool get active => _active;
  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsCompositingBitsUpdate();
    _moved();
  }

  /// A pose para o bloco que vai de [top] a [bottom], medidos a partir do
  /// alto de uma tela de altura [extent].
  SpacePose poseFor(double top, double bottom, double extent);

  void _moved() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position?.addListener(_moved);
    _geometry?.addListener(_moved);
  }

  @override
  void detach() {
    _position?.removeListener(_moved);
    _geometry?.removeListener(_moved);
    super.detach();
  }

  @override
  void dispose() {
    _fade.layer = null;
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _active;

  /// A pose do quadro atual. Fora de uma rolagem vertical, o bloco fica em
  /// repouso: o efeito é de rolagem, e sem ela não há do que depender.
  SpacePose _currentPose() {
    final viewport = RenderAbstractViewport.maybeOf(parent);
    if (!_active || viewport is! RenderViewportBase) return SpacePose.rest;
    if (viewport.axis != Axis.vertical || !viewport.hasSize) {
      return SpacePose.rest;
    }
    final toViewport = getTransformTo(viewport);
    final top = MatrixUtils.transformPoint(toViewport, Offset.zero).dy;
    final bottom = MatrixUtils.transformPoint(
      toViewport,
      Offset(0, size.height),
    ).dy;
    return poseFor(top, bottom, viewport.size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final pose = _currentPose();
    if (pose.isFlat && pose.alpha == 255) {
      _transform = null;
      layer = null;
      _fade.layer = null;
      super.paint(context, offset);
      return;
    }
    final matrix = pose.matrix(size);
    _transform = matrix;
    layer = context.pushTransform(
      needsCompositing,
      offset,
      matrix,
      (context, offset) => _paintFaded(context, offset, pose.alpha),
      oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
    );
  }

  void _paintFaded(PaintingContext context, Offset offset, int alpha) {
    if (alpha == 255) {
      _fade.layer = null;
      super.paint(context, offset);
      return;
    }
    _fade.layer = context.pushOpacity(
      offset,
      alpha,
      super.paint,
      oldLayer: _fade.layer,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) =>
          super.hitTestChildren(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final own = _transform;
    if (own != null) transform.multiply(own);
  }
}
