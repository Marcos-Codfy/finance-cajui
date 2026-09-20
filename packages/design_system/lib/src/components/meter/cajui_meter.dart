import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:flutter/widgets.dart';

/// O medidor: quanto de um limite já foi usado.
///
/// É um dos dois únicos gráficos do app — só existe onde há parte-todo ou
/// progresso (RN-862). Nunca aparece sem o número equivalente em texto ao
/// lado; aqui, o próprio medidor exige esse texto em [semanticValue].
///
/// Passar do limite não pinta o medidor de alarme: a barra enche e muda para
/// a cor da falta, e é o texto ao lado que diz "passou R$ 23,75 do limite".
class CajuiMeter extends StatelessWidget {
  /// Cria um medidor com [value] entre 0 e 1. Acima de 1 significa que
  /// passou do limite.
  const new({
    required this.value,
    required this.semanticLabel,
    required this.semanticValue,
    this.fill,
    super.key,
  });

  /// A fração usada. Pode passar de 1.
  final double value;

  /// O que o medidor mede: "Limite da semana".
  final String semanticLabel;

  /// O valor por extenso: "R$ 120,00 de R$ 226,47".
  final String semanticValue;

  /// A cor do preenchimento. Por padrão, `data.variable`.
  final Color? fill;

  static const double _height = 10;
  static const _radius = BorderRadius.all(CajuiRadius.pill);

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    final over = value > 1;
    final color = over ? colors.shortfall : (fill ?? colors.data.variable);
    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      child: ClipRRect(
        borderRadius: _radius,
        child: ColoredBox(
          color: colors.data.track,
          child: SizedBox(
            height: _height,
            child: _bar(color, animate: theme.motionLevel.allowsSpring),
          ),
        ),
      ),
    );
  }

  Widget _bar(Color color, {required bool animate}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1).toDouble()),
      duration: animate ? CajuiDurations.slow : Duration.zero,
      curve: CajuiCurves.enter,
      builder: (context, fraction, _) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: _radius),
        ),
      ),
    );
  }
}
