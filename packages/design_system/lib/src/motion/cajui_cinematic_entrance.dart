import 'package:design_system/src/motion/cinematic_timeline.dart';
import 'package:design_system/src/motion/light_sweep_painter.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// A entrada cinematográfica: o travelling de câmera quando uma tela abre.
///
/// Os blocos marcados com `CajuiCinematicShot` chegam da profundidade em
/// cascata — de longe e fora de foco para perto e nítido —, assentam com
/// mola, e uma faixa de luz cruza a tela uma vez enquanto eles param.
///
/// Roda **uma vez** por montagem, e de novo só quando [replayKey] muda — o
/// mês trocado, por exemplo. Nunca em laço (RNF-A11Y-08), e a cascata inteira
/// cabe nos 600 ms de `CajuiDurations.slowest`. Espera a tela estar à vista:
/// montada por baixo de outra aba, ela começa quando aparece, e não às
/// escuras.
///
/// No `lite` não há desfoque nem luz; no `reduced`, os blocos só esmaecem,
/// juntos, em 120 ms.
class CajuiCinematicEntrance extends StatefulWidget {
  /// Encena a entrada dos blocos marcados dentro de [child].
  const new({
    required this.child,
    this.replayKey,
    this.sweep = true,
    super.key,
  });

  /// A tela, com os blocos marcados por `CajuiCinematicShot`.
  final Widget child;

  /// Quando muda, a entrada roda de novo.
  final Object? replayKey;

  /// Se a faixa de luz cruza a tela. Desligue em tela sem um número de
  /// destaque: luz sobre uma lista comum vira enfeite sem motivo.
  final bool sweep;

  @override
  State<CajuiCinematicEntrance> createState() => _CajuiCinematicEntranceState();
}

class _CajuiCinematicEntranceState extends State<CajuiCinematicEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this);
  MotionLevel _motion = MotionLevel.full;
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionOf(context);
    _progress.duration = _motion == MotionLevel.reduced
        ? CajuiDurations.reducedFade
        : CajuiDurations.slowest;
    _playWhenVisible();
  }

  @override
  void didUpdateWidget(CajuiCinematicEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayKey == widget.replayKey) return;
    _played = false;
    _playWhenVisible();
  }

  /// Só começa com a tela à vista: o relógio de uma aba escondida anda sem
  /// pintar, e a entrada acabaria antes de alguém vê-la.
  void _playWhenVisible() {
    if (_played || !TickerMode.valuesOf(context).enabled) return;
    _played = true;
    _progress.forward(from: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  /// A forma da árvore é a mesma com ou sem luz: o nível de movimento pode
  /// cair no meio da sessão (quadros perdidos viram `lite`), e trocar a
  /// forma remontaria a tela inteira — e a rolagem voltaria ao topo.
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: CinematicTimeline(
            progress: _progress,
            motion: _motion,
            child: widget.child,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(painter: _sweep(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A luz, só no `full` e só se pedida; sem ela, a camada fica vazia.
  CustomPainter? _sweep(BuildContext context) {
    if (!widget.sweep || !_motion.allowsDecorativeMotion) return null;
    final brand = CajuiTheme.of(context).colors.brand;
    return LightSweepPainter(
      progress: _progress,
      light: brand.sheen,
      warmth: brand.gold,
    );
  }
}
