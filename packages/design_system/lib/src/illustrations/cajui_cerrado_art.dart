import 'dart:math' as math;

import 'package:design_system/src/illustrations/cajui_cerrado.dart';
import 'package:design_system/src/illustrations/cerrado_painter.dart';
import 'package:design_system/src/illustrations/cerrado_palette.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// Uma ilustração leve do Cerrado (`CajuiCerrado`), para o estado vazio.
///
/// Balança devagar, como planta ao vento, só no nível de movimento
/// completo; nos outros fica parada, de pé — é enfeite, e enfeite é o
/// primeiro a sair. As cores vêm do tema, então o claro e o escuro saem do
/// mesmo desenho.
class CajuiCerradoArt extends StatefulWidget {
  /// Cria a ilustração [kind] com [size] de lado.
  const new(this.kind, {this.size = 128, this.semanticLabel, super.key});

  /// Qual ilustração: o cajuí, a folha ou o ipê.
  final CajuiCerrado kind;

  /// O lado do desenho.
  final double size;

  /// Descrição para o leitor de tela. Sem ela, a ilustração é decorativa: o
  /// título do vazio já diz tudo.
  final String? semanticLabel;

  @override
  State<CajuiCerradoArt> createState() => _CajuiCerradoArtState();
}

class _CajuiCerradoArtState extends State<CajuiCerradoArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breeze = AnimationController(
    vsync: this,
    duration: CajuiDurations.breeze,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final decorative = CajuiTheme.of(context)
        .motionLevel
        .allowsDecorativeMotion;
    decorative ? _breeze.repeat() : _breeze.stop();
  }

  @override
  void dispose() {
    _breeze.dispose();
    super.dispose();
  }

  /// Parado, o balanço é zero: o desenho de pé, e não o quadro em que o
  /// movimento foi interrompido.
  double get _sway =>
      _breeze.isAnimating ? math.sin(_breeze.value * 2 * math.pi) : 0;

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticLabel;
    final palette = CerradoPalette.of(CajuiTheme.of(context).colors);
    return Semantics(
      label: label,
      image: label != null,
      excludeSemantics: label == null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _breeze,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: CerradoPainter(
              kind: widget.kind,
              palette: palette,
              sway: _sway,
            ),
          ),
        ),
      ),
    );
  }
}
