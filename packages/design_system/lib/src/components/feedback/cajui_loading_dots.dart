import 'dart:math' as math;

import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// Três pontos que respiram: o "carregando" do Cajui.
///
/// Respiram, não giram — é o que a marca pede para o estado de espera. No
/// nível de movimento reduzido ficam parados, sem perder o significado: o
/// leitor de tela continua anunciando o rótulo.
class CajuiLoadingDots extends StatefulWidget {
  /// Cria o indicador na cor [color], com pontos de [dotSize] de diâmetro.
  const new({
    required this.color,
    this.dotSize = 6,
    this.semanticLabel = 'Carregando',
    super.key,
  });

  /// A cor dos pontos.
  final Color color;

  /// O diâmetro de cada ponto.
  final double dotSize;

  /// O que o leitor de tela anuncia.
  final String semanticLabel;

  @override
  State<CajuiLoadingDots> createState() => _CajuiLoadingDotsState();
}

class _CajuiLoadingDotsState extends State<CajuiLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = CajuiTheme.of(context).motionLevel.allowsSpring;
    animate ? _breath.repeat() : _breath.stop();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// Cada ponto respira com um terço de ciclo de atraso em relação ao vizinho.
  double _opacity(int index) {
    if (!_breath.isAnimating) return 0.7;
    final phase = (_breath.value - index / 3) * 2 * math.pi;
    return 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < 3; i++) _dot(i)],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.dotSize / 3),
      child: Opacity(
        opacity: _opacity(index),
        child: SizedBox.square(
          dimension: widget.dotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
