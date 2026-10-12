import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:design_system/src/feedback/cajui_feedback_scope.dart';
import 'package:design_system/src/motion/light_sweep_painter.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/semantic/brand_colors.dart';
import 'package:flutter/widgets.dart';

/// A chegada pelo widget da tela inicial: o número atravessa o vidro.
///
/// O widget do Cajui é um painel de vidro sobre a aurora do Cerrado
/// (`brand.aurora`). Tocar no número abre o app crescendo de dentro dele
/// (Android 12+), e esta é a outra metade do gesto: o bloco chega ainda
/// coberto pelo véu fosco do vidro, um pouco menor, com a aurora acesa por
/// trás; o véu se desfaz, o bloco assenta com mola, a aurora se apaga e a
/// faixa de luz cruza uma vez. Com o pop do card, o mesmo do toque.
///
/// Roda quando [arrival] muda para um valor que não é zero — uma chegada,
/// uma vez, nunca em laço (RNF-A11Y-08) —, e cabe nos 600 ms de
/// `CajuiDurations.slowest`. No `lite` não há aurora nem luz; no `reduced`,
/// só o véu se desfaz, em 120 ms.
class CajuiGlassArrival extends StatefulWidget {
  /// Encena a chegada de [child] a cada [arrival] novo.
  const new({required this.child, this.arrival = 0, super.key});

  /// O bloco que chega: os números do mês.
  final Widget child;

  /// Muda a cada toque no widget; zero é nenhuma chegada.
  final int arrival;

  @override
  State<CajuiGlassArrival> createState() => _CajuiGlassArrivalState();
}

class _CajuiGlassArrivalState extends State<CajuiGlassArrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    value: 1,
  );
  MotionLevel _motion = MotionLevel.full;
  int _played = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionOf(context);
    _clock.duration = _motion == MotionLevel.reduced
        ? CajuiDurations.reducedFade
        : CajuiDurations.slowest;
    _arrive();
  }

  @override
  void didUpdateWidget(CajuiGlassArrival oldWidget) {
    super.didUpdateWidget(oldWidget);
    _arrive();
  }

  /// Uma vez por chegada: o mesmo número não toca de novo quando a tela só
  /// se redesenha.
  void _arrive() {
    if (widget.arrival == 0 || widget.arrival == _played) return;
    _played = widget.arrival;
    CajuiFeedbackScope.of(context).cardTapped();
    _clock.forward(from: 0);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// A forma da árvore é a mesma parado ou chegando: trocá-la remontaria os
  /// números, e o carrossel perderia a página.
  @override
  Widget build(BuildContext context) {
    final brand = CajuiTheme.of(context).colors.brand;
    final decorative = _motion.allowsDecorativeMotion;
    return AnimatedBuilder(
      animation: _clock,
      child: widget.child,
      builder: (context, child) => Stack(
        children: [
          Transform.scale(
            scale: _scale(_clock.value),
            child: DecoratedBox(
              decoration: _glow(brand.aurora, decorative ? _clock.value : 1),
              child: child,
            ),
          ),
          Positioned.fill(child: _veil(brand.sheen, _clock.value)),
          Positioned.fill(child: _sweep(brand, on: decorative)),
        ],
      ),
    );
  }

  /// De 0,9 ao tamanho certo, com a mola de assentar; sem mola no
  /// `reduced`, que só esmaece.
  double _scale(double t) {
    if (!_motion.allowsSpring || t >= 1) return 1;
    return lerpDouble(0.9, 1, CajuiCurves.settle.transform(t))!;
  }

  /// A aurora acende e se apaga no meio da chegada: forte no começo, nada
  /// no fim. Três luzes, uma de cada lado, como no fundo do widget.
  BoxDecoration _glow(List<Color> aurora, double t) {
    final strength = t >= 1 ? 0.0 : math.sin(math.pi * math.min(1, t * 1.4));
    if (strength <= 0) return const BoxDecoration();
    const offsets = [Offset(-28, -12), Offset(28, 0), Offset(0, 24)];
    return BoxDecoration(
      borderRadius: const BorderRadius.all(CajuiRadius.xl),
      boxShadow: [
        for (final (index, color) in aurora.indexed)
          BoxShadow(
            color: color.withValues(alpha: 0.55 * strength),
            blurRadius: 48,
            spreadRadius: 4,
            offset: offsets[index % offsets.length],
          ),
      ],
    );
  }

  /// O véu fosco do vidro: cobre o bloco e se desfaz na primeira metade.
  Widget _veil(Color sheen, double t) {
    final left = t >= 1
        ? 0.0
        : 1 - CajuiCurves.enter.transform(math.min(1, t / 0.55));
    if (left <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(CajuiRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                sheen.withValues(alpha: 0.7 * left),
                sheen.withValues(alpha: 0.35 * left),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A faixa de luz da entrada cinematográfica, uma vez, no fim; fora do
  /// `full`, a camada fica vazia, sem mudar a forma da árvore.
  Widget _sweep(BrandColors brand, {required bool on}) => IgnorePointer(
    child: ExcludeSemantics(
      child: CustomPaint(
        painter: on
            ? LightSweepPainter(
                progress: _clock,
                light: brand.sheen,
                warmth: brand.gold,
              )
            : null,
      ),
    ),
  );
}
