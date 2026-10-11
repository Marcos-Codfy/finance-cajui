import 'package:design_system/src/components/chart/cajui_chart_bar.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Uma coluna do gráfico: a barra, o pedaço da linha do zero, o nome do mês
/// e a marca de escolhido.
///
/// A coluna inteira é o alvo de toque — no mínimo 48 de largura —, e não só
/// a barra: barra de mês apertado seria fina demais para o dedo.
class BarSlot extends StatelessWidget {
  /// Cria a coluna da [bar].
  const new({
    required this.bar,
    required this.width,
    required this.scale,
    required this.above,
    required this.below,
    required this.grow,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  /// O mês.
  final CajuiChartBar bar;

  /// A largura da coluna.
  final double width;

  /// Pixels por centavo: a mesma escala para todas as barras.
  final double scale;

  /// A altura da área acima da linha do zero.
  final double above;

  /// A altura da área abaixo da linha do zero.
  final double below;

  /// Quanto a barra já cresceu, de 0 a pouco mais de 1 (a mola passa).
  final double grow;

  /// Se este é o mês em destaque.
  final bool selected;

  /// O que acontece ao tocar.
  final VoidCallback onPressed;

  /// A barra mais larga: além disso, ela vira bloco e deixa de ler como mês.
  static const double _maxBarWidth = 28;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final up = bar.cents >= 0;
    return CajuiPressable(
      onPressed: onPressed,
      semanticLabel: bar.spoken,
      selected: selected,
      radius: const BorderRadius.all(CajuiRadius.sm),
      builder: (context, _) => SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: above, child: up ? _bar(theme, up: true) : null),
            SizedBox(
              height: 1,
              width: width,
              child: ColoredBox(color: theme.colors.border.field),
            ),
            SizedBox(height: below, child: up ? null : _bar(theme, up: false)),
            const SizedBox(height: CajuiSpacing.sm),
            _label(theme),
            const SizedBox(height: CajuiSpacing.xs),
            _marker(theme),
          ],
        ),
      ),
    );
  }

  /// A barra cresce a partir da linha do zero: para cima a sobra, para
  /// baixo a falta. A sobra no tom dela; a falta no tom neutro — o mês que
  /// não fechou é fato, não bronca.
  Widget _bar(CajuiThemeData theme, {required bool up}) {
    final colors = theme.colors;
    const round = CajuiRadius.xs;
    return Align(
      alignment: up ? Alignment.bottomCenter : Alignment.topCenter,
      child: Transform.scale(
        scaleY: grow,
        alignment: up ? Alignment.bottomCenter : Alignment.topCenter,
        child: SizedBox(
          width: (width * 0.56).clamp(8, _maxBarWidth).toDouble(),
          height: bar.cents.abs() * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: up ? colors.intent.positive : colors.data.fixed,
              borderRadius: up
                  ? const BorderRadius.vertical(top: round)
                  : const BorderRadius.vertical(bottom: round),
            ),
          ),
        ),
      ),
    );
  }

  /// O escolhido se marca pelo peso e pela cor do nome e por um traço: nunca
  /// só pela cor.
  Widget _label(CajuiThemeData theme) {
    final colors = theme.colors;
    return Text(
      bar.label,
      maxLines: 1,
      style: theme.typography.caption.copyWith(
        color: selected ? colors.text.primary : colors.text.faint,
        fontVariations: [FontVariation('wght', selected ? 600 : 400)],
      ),
    );
  }

  Widget _marker(CajuiThemeData theme) {
    return SizedBox(
      width: 16,
      height: 3,
      child: selected
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.text.primary,
                borderRadius: const BorderRadius.all(CajuiRadius.pill),
              ),
            )
          : null,
    );
  }
}
