import 'dart:ui' show lerpDouble;

import 'package:design_system/src/components/carousel/cover_flow_slide.dart';
import 'package:design_system/src/interaction/focus_ring.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Os pontos do carrossel: onde se está, e um jeito de ir a qualquer página
/// sem arrastar.
///
/// O ponto da página atual vira uma pílula — forma, e não só cor, marca a
/// posição (RNF-A11Y-03) —, e a pílula escorre de um ponto ao outro junto
/// com o dedo, porque é pintada a partir da posição contínua do carrossel.
///
/// É **um controle só**, de 48 de altura: pontos separados seriam alvos
/// pequenos demais, e 48 entre um e outro, uma régua. Para o leitor de
/// tela, é um ajuste: "Página 2 de 4", deslize para cima ou para baixo.
/// No teclado, as setas trocam a página.
class CoverFlowIndicator extends StatefulWidget {
  /// Cria os pontos de [count] páginas, na posição contínua [page].
  const new({
    required this.count,
    required this.page,
    required this.current,
    required this.label,
    required this.onSelect,
    super.key,
  });

  /// Quantas páginas há.
  final int count;

  /// A posição contínua do carrossel, em páginas.
  final ValueListenable<double> page;

  /// A página em que o carrossel assentou ou vai assentar.
  final int current;

  /// O nome do carrossel, para o leitor de tela.
  final String label;

  /// Leva o carrossel à página pedida.
  final ValueChanged<int> onSelect;

  @override
  State<CoverFlowIndicator> createState() => _CoverFlowIndicatorState();
}

class _CoverFlowIndicatorState extends State<CoverFlowIndicator> {
  static const double _dot = 6;
  static const double _pill = 20;
  static const double _gap = 8;
  bool _focused = false;

  double get _width =>
      widget.count * _dot + (_pill - _dot) + (widget.count - 1) * _gap;

  void _step(int delta) {
    final next = (widget.current + delta).clamp(0, widget.count - 1);
    if (next != widget.current) widget.onSelect(next);
  }

  /// O toque escolhe o ponto mais perto: a pílula ocupa o lugar de um ponto
  /// largo, e os outros ficam em passo fixo.
  void _tapAt(Offset local, double boxWidth) {
    final start = (boxWidth - _width) / 2;
    final pitch = _width / widget.count;
    final index = ((local.dx - start) / pitch).floor();
    widget.onSelect(index.clamp(0, widget.count - 1));
  }

  String? _spoken(int index) => index >= 0 && index < widget.count
      ? CoverFlowSlide.spoken(index, widget.count)
      : null;

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final last = widget.count - 1;
    return Semantics(
      slider: true,
      label: widget.label,
      value: _spoken(current),
      increasedValue: _spoken(current + 1),
      decreasedValue: _spoken(current - 1),
      onIncrease: current < last ? () => _step(1) : null,
      onDecrease: current > 0 ? () => _step(-1) : null,
      child: ExcludeSemantics(child: _keys(context)),
    );
  }

  Widget _keys(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (on) => setState(() => _focused = on),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _Step(1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _Step(-1),
      },
      actions: {
        _Step: CallbackAction<_Step>(onInvoke: (step) => _step(step.delta)),
      },
      child: _surface(context),
    );
  }

  Widget _surface(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    final box = _width + 2 * CajuiSpacing.lg;
    return FocusRing(
      visible: _focused,
      radius: const BorderRadius.all(CajuiRadius.pill),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (tap) => _tapAt(tap.localPosition, box),
        child: SizedBox(
          width: box,
          height: CajuiSpacing.touchTarget,
          child: CustomPaint(
            painter: _DotsPainter(
              page: widget.page,
              count: widget.count,
              on: colors.text.primary,
              off: colors.border.strong,
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends Intent {
  const new(this.delta);

  final int delta;
}

/// Pinta os pontos a cada quadro do carrossel, sem reconstruir nada: a
/// largura de cada ponto vem da distância dele à posição contínua.
class _DotsPainter extends CustomPainter {
  new({
    required this.page,
    required this.count,
    required this.on,
    required this.off,
  }) : super(repaint: page);

  final ValueListenable<double> page;
  final int count;
  final Color on;
  final Color off;

  @override
  void paint(Canvas canvas, Size size) {
    const dot = _CoverFlowIndicatorState._dot;
    const pill = _CoverFlowIndicatorState._pill;
    const gap = _CoverFlowIndicatorState._gap;
    final total = count * dot + (pill - dot) + (count - 1) * gap;
    var x = (size.width - total) / 2;
    final y = size.height / 2;
    for (var i = 0; i < count; i++) {
      final near = (1 - (page.value - i).abs()).clamp(0.0, 1.0);
      final width = lerpDouble(dot, pill, near)!;
      final rect = Rect.fromLTWH(x, y - dot / 2, width, dot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(dot / 2)),
        Paint()..color = Color.lerp(off, on, near)!,
      );
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.on != on ||
      oldDelegate.off != off ||
      oldDelegate.page != page;
}
