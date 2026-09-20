import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma pista com um ponto que a percorre numa curva e numa duração: dá para
/// ver a diferença entre 180 e 420 ms, e a ultrapassagem da mola.
class CurveTrack extends StatefulWidget {
  /// Cria a pista. Mudar [run] faz o ponto percorrer de novo.
  const new({
    required this.curve,
    required this.duration,
    required this.run,
    super.key,
  });

  /// A curva do percurso.
  final Curve curve;

  /// Quanto o percurso dura.
  final Duration duration;

  /// Contador de disparos: cada valor novo roda o percurso outra vez.
  final int run;

  @override
  State<CurveTrack> createState() => _CurveTrackState();
}

class _CurveTrackState extends State<CurveTrack>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  static const double _dot = 16;

  @override
  void didUpdateWidget(CurveTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run == widget.run) return;
    // Com movimento reduzido o ponto já aparece no destino: a mesa obedece à
    // mesma regra que o app.
    final reduced = CajuiTheme.of(context).motionLevel == MotionLevel.reduced;
    if (reduced) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return Container(
      height: _dot,
      // A folga à direita é o espaço da ultrapassagem da mola.
      margin: const EdgeInsets.only(right: CajuiSpacing.section),
      decoration: BoxDecoration(
        color: colors.data.track,
        borderRadius: const BorderRadius.all(CajuiRadius.pill),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, dot) => Align(
          alignment: Alignment(
            widget.curve.transform(_controller.value) * 2 - 1,
            0,
          ),
          child: dot,
        ),
        child: Container(
          width: _dot,
          height: _dot,
          decoration: BoxDecoration(
            color: colors.brand.accent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
