import 'dart:math' as math;

import 'package:design_system/src/illustrations/hero_fruit_painter.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// O cajuí em volume: o ícone-herói de abertura, estado vazio e conquista.
///
/// No máximo um por tela (regra da iconografia). Flutua devagar só no nível
/// de movimento completo; nos outros fica parado, no quadro de repouso — o
/// herói animado é enfeite, e enfeite é o primeiro a sair.
class CajuiHeroFruit extends StatefulWidget {
  /// Cria o herói com [size] de lado.
  const new({this.size = 160, this.semanticLabel, super.key});

  /// O lado do desenho.
  final double size;

  /// Descrição para o leitor de tela. Sem ela, o herói é decorativo.
  final String? semanticLabel;

  @override
  State<CajuiHeroFruit> createState() => _CajuiHeroFruitState();
}

class _CajuiHeroFruitState extends State<CajuiHeroFruit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final decorative = CajuiTheme.of(context).motionLevel.allowsDecorativeMotion;
    decorative ? _float.repeat() : _float.stop();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  double get _lift {
    if (!_float.isAnimating) return 0;
    return 0.5 - 0.5 * math.cos(_float.value * 2 * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticLabel;
    return Semantics(
      label: label,
      image: label != null,
      excludeSemantics: label == null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: HeroFruitPainter(lift: _lift),
          ),
        ),
      ),
    );
  }
}
