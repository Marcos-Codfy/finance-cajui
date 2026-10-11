import 'dart:ui' show lerpDouble;

import 'package:design_system/src/components/carousel/carousel_pose.dart';
import 'package:design_system/src/components/carousel/cover_flow_indicator.dart';
import 'package:design_system/src/components/carousel/cover_flow_slide.dart';
import 'package:design_system/src/feedback/cajui_feedback_scope.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/primitives/cajui_springs.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// O carrossel 3D: páginas lado a lado num tambor, a do centro de frente e
/// as vizinhas girando para longe.
///
/// Feito para poucos blocos irmãos que a pessoa folheia — os números do mês
/// no alto do Início: sobra, o que entra, o que sai, o vale. Arrasta-se de
/// lado (o arrasto vertical continua rolando a tela), e a página **encaixa**
/// com mola (`CajuiSprings.page`), com o deslize e o pulso de tecla do
/// retorno sensorial. Um gesto rápido passa uma página só, como num livro.
///
/// Sem arrastar também se chega a tudo (RNF-A11Y-10): tocar numa vizinha a
/// traz para o centro; os pontos embaixo levam a qualquer página, pelo toque
/// ou pelas setas; o leitor de tela ouve "Página 2 de 4" em cada página e
/// pode ajustar a posição pelos pontos.
///
/// A altura é a da página mais alta: com fonte grande, o carrossel cresce,
/// em vez de cortar texto. Todas as páginas ficam montadas — é para poucos
/// blocos; lista longa pede outra coisa.
///
/// No `reduced`, as páginas ficam planas, lado a lado, e trocar de página é
/// um corte com esmaecer curto.
class CajuiCoverFlow extends StatefulWidget {
  /// Cria o carrossel com as páginas [children], chamado [semanticLabel]
  /// pelo leitor de tela.
  const new({
    required this.children,
    required this.semanticLabel,
    this.initialPage = 0,
    this.onPageChanged,
    this.viewportFraction = 0.8,
    super.key,
  }) : assert(
         viewportFraction > 0.5 && viewportFraction <= 1,
         'A página do centro precisa ocupar a maior parte do palco.',
       );

  /// As páginas, da primeira à última. Sem nenhuma, o carrossel não ocupa
  /// lugar.
  final List<Widget> children;

  /// O nome do carrossel para o leitor de tela: "Números do mês".
  final String semanticLabel;

  /// A página que aparece primeiro.
  final int initialPage;

  /// Avisa quando a página escolhida muda — no soltar do dedo, e não no fim
  /// da mola: a resposta vem antes do espetáculo.
  final ValueChanged<int>? onPageChanged;

  /// A fração da largura que a página do centro ocupa. O resto mostra um
  /// pedaço das vizinhas: é o que conta que há mais para ver.
  final double viewportFraction;

  @override
  State<CajuiCoverFlow> createState() => _CajuiCoverFlowState();
}

class _CajuiCoverFlowState extends State<CajuiCoverFlow>
    with TickerProviderStateMixin {
  /// Entre o centro de uma página e o da seguinte, em larguras de página.
  /// Menos que uma: girada, a vizinha enfia a borda de dentro uns pixels
  /// atrás da página do centro — é o que dá a leitura de profundidade — e
  /// mostra uns 50 px na beirada da tela, o bastante para ser tocada.
  static const double _neighborSpacing = 0.8;

  /// Além da primeira e da última página, o dedo puxa com esta fração da
  /// força: a ponta cede um pouco e volta, em vez de travar seco.
  static const double _edgeGive = 0.3;

  /// Quantos segundos de embalo o gesto projeta ao soltar.
  static const double _momentum = 0.18;

  late final AnimationController _page = AnimationController.unbounded(
    vsync: this,
    value: _clamp(widget.initialPage).toDouble(),
  );

  /// O esmaecer do movimento reduzido, que substitui a viagem da página.
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: CajuiDurations.reducedFade,
    value: 1,
  );

  late int _current = _clamp(widget.initialPage);
  MotionLevel _motion = MotionLevel.full;
  double _spacing = 1;
  double _finger = 0;
  int _origin = 0;

  int get _last => widget.children.length - 1;

  int _clamp(int index) =>
      widget.children.isEmpty ? 0 : index.clamp(0, widget.children.length - 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionOf(context);
  }

  @override
  void didUpdateWidget(CajuiCoverFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_current <= _last || widget.children.isEmpty) return;
    _current = _last;
    _page.value = _last.toDouble();
  }

  @override
  void dispose() {
    _page.dispose();
    _arrive.dispose();
    super.dispose();
  }

  void _dragStart(DragStartDetails _) {
    _page.stop();
    _finger = _page.value;
    _origin = _clamp(_page.value.round());
  }

  void _dragUpdate(DragUpdateDetails drag) {
    _finger -= (drag.primaryDelta ?? 0) / _spacing;
    _page.value = _resist(_finger);
  }

  double _resist(double value) {
    if (value < 0) return value * _edgeGive;
    if (value > _last) return _last + (value - _last) * _edgeGive;
    return value;
  }

  void _dragEnd(DragEndDetails drag) {
    final velocity = -(drag.primaryVelocity ?? 0) / _spacing;
    final projected = (_page.value + velocity * _momentum).round();
    _settle(_clamp(projected.clamp(_origin - 1, _origin + 1)), velocity);
  }

  void _dragCancel() => _settle(_clamp(_page.value.round()), 0);

  void _goTo(int index) => _settle(index, 0);

  void _settle(int target, double velocity) {
    if (target != _current) {
      setState(() => _current = target);
      CajuiFeedbackScope.of(context).pageTurned();
      widget.onPageChanged?.call(target);
    }
    if (_motion == MotionLevel.reduced) {
      _page.value = target.toDouble();
      _arrive.forward(from: 0);
      return;
    }
    final spring = SpringSimulation(
      CajuiSprings.page,
      _page.value,
      target.toDouble(),
      velocity,
    );
    _page.animateWith(spring);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => _stage(constraints.maxWidth),
          ),
          const SizedBox(height: CajuiSpacing.sm),
          CoverFlowIndicator(
            count: widget.children.length,
            page: _page,
            current: _current,
            label: widget.semanticLabel,
            onSelect: _goTo,
          ),
        ],
      ),
    );
  }

  /// O palco tem a largura toda; a página, a fração dela. As vizinhas são
  /// pintadas além da borda da página e continuam tocáveis dentro do palco.
  Widget _stage(double width) {
    final pageWidth = width * widget.viewportFraction;
    _spacing = pageWidth * _neighborSpacing + CajuiSpacing.sm;
    return GestureDetector(
      onHorizontalDragStart: _dragStart,
      onHorizontalDragUpdate: _dragUpdate,
      onHorizontalDragEnd: _dragEnd,
      onHorizontalDragCancel: _dragCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_page, _arrive]),
        builder: (context, _) => SizedBox(
          width: width,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [for (final i in _paintOrder()) _slide(i, pageWidth)],
          ),
        ),
      ),
    );
  }

  /// A de mais longe primeiro, a do centro por último: a do centro fica por
  /// cima, e é ela quem recebe o toque. A ordem de leitura não muda — cada
  /// página leva a própria chave de ordem.
  List<int> _paintOrder() {
    final page = _page.value;
    double reach(int index) => (index - page).abs();
    return [for (var i = 0; i <= _last; i++) i]..sort((a, b) {
      final byReach = reach(b).compareTo(reach(a));
      return byReach != 0 ? byReach : a.compareTo(b);
    });
  }

  Widget _slide(int index, double pageWidth) {
    final centered = index == _clamp(_page.value.round());
    return CoverFlowSlide(
      key: ValueKey(index),
      index: index,
      count: widget.children.length,
      pose: _pose(index, centered: centered),
      width: pageWidth,
      centered: centered,
      onSummon: () => _goTo(index),
      child: widget.children[index],
    );
  }

  SpacePose _pose(int index, {required bool centered}) {
    final flat = _motion == MotionLevel.reduced;
    final pose = CarouselPose.of(
      index - _page.value,
      spacing: _spacing,
      flat: flat,
    );
    if (!flat || !centered) return pose;
    final fade = CajuiCurves.standard.transform(_arrive.value);
    return SpacePose(shift: pose.shift, opacity: lerpDouble(0.4, 1, fade)!);
  }
}
