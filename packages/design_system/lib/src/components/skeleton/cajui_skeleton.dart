import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:flutter/widgets.dart';

/// O esqueleto: a forma do conteúdo que ainda está chegando.
///
/// Mostrar o contorno do que vem evita o salto de layout quando os dados
/// aparecem, e é mais calmo que um indicador girando no meio da tela. Respira
/// devagar; no movimento reduzido, fica parado.
class CajuiSkeleton extends StatefulWidget {
  /// Um bloco com [width] e [height].
  const new({
    required this.height,
    this.width,
    this.radius = const BorderRadius.all(CajuiRadius.sm),
    super.key,
  });

  /// Uma linha de texto: 14 de altura, cantos em cápsula.
  const new line({this.width, super.key})
    : height = 14,
      radius = const BorderRadius.all(CajuiRadius.pill);

  /// A largura. Sem ela, ocupa o que houver.
  final double? width;

  /// A altura.
  final double height;

  /// O raio de canto.
  final BorderRadius radius;

  @override
  State<CajuiSkeleton> createState() => _CajuiSkeletonState();
}

class _CajuiSkeletonState extends State<CajuiSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = CajuiTheme.of(context).motionLevel.allowsSpring;
    animate ? _breath.repeat(reverse: true) : _breath.stop();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = CajuiTheme.of(context).colors.data.track;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) => Opacity(
          opacity: _breath.isAnimating ? 0.55 + 0.45 * _breath.value : 0.8,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: widget.radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
