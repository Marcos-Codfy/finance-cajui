import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// Conta do valor antigo até o novo: o número que muda diante do olho, em
/// vez de trocar de repente.
///
/// Trabalha com inteiros — centavos —, então nenhum valor intermediário
/// inventa fração de centavo. Como o texto usa algarismos tabulares, a largura
/// não treme durante a contagem.
///
/// No movimento reduzido o valor simplesmente muda. E o leitor de tela só
/// conhece o valor final: quem desenha o número anuncia [value], nunca o
/// valor em trânsito.
class CajuiCountUp extends StatelessWidget {
  /// Anima até [value]; [builder] desenha o valor em trânsito.
  const new({required this.value, required this.builder, super.key});

  /// O valor de chegada, em centavos.
  final int value;

  /// Desenha um valor. Recebe os centavos em trânsito.
  final Widget Function(BuildContext context, int cents) builder;

  @override
  Widget build(BuildContext context) {
    final animate = CajuiTheme.of(context).motionLevel.allowsDecorativeMotion;
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: value),
      duration: animate ? CajuiDurations.slow : Duration.zero,
      curve: CajuiCurves.enter,
      builder: (context, cents, _) => builder(context, cents),
    );
  }
}
