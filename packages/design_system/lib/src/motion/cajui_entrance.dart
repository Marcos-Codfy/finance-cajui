import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// A entrada em cascata: o item sobe 12 px enquanto aparece, com um pequeno
/// atraso conforme a posição na lista.
///
/// Roda uma vez, ao entrar — nunca em laço, que é o que a WCAG 2.2.2 pede de
/// conteúdo que se move sozinho. No movimento reduzido não há cascata: o item
/// simplesmente está lá.
class CajuiEntrance extends StatefulWidget {
  /// Anima a entrada de [child]. [index] é a posição na lista.
  const new({required this.child, this.index = 0, super.key});

  /// O conteúdo.
  final Widget child;

  /// A posição na lista, que define o atraso. Limitada a 8: lista longa não
  /// pode demorar segundos para terminar de entrar.
  final int index;

  @override
  State<CajuiEntrance> createState() => _CajuiEntranceState();
}

class _CajuiEntranceState extends State<CajuiEntrance>
    with SingleTickerProviderStateMixin {
  static const double _rise = 12;
  static const int _maxStaggeredItems = 8;

  late final Duration _delay =
      CajuiDurations.stagger * widget.index.clamp(0, _maxStaggeredItems);

  /// O atraso mora dentro da animação, como um intervalo parado no começo,
  /// e não num temporizador: assim nada fica pendente se o item sair da tela
  /// antes de começar a entrar.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _delay + CajuiDurations.base,
  );

  late final Animation<double> _entrance = CurvedAnimation(
    parent: _progress,
    curve: Interval(
      _delay.inMicroseconds / (_delay + CajuiDurations.base).inMicroseconds,
      1,
      curve: CajuiCurves.enter,
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final animate = CajuiTheme.of(context).motionLevel.allowsSpring;
    animate ? _progress.forward() : _progress.value = 1;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _entrance.value,
        child: Transform.translate(
          offset: Offset(0, _rise * (1 - _entrance.value)),
          child: child,
        ),
      ),
    );
  }
}
