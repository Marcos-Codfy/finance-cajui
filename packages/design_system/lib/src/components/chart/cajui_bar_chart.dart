import 'dart:math' as math;

import 'package:design_system/src/components/amount/cajui_amount_tone.dart';
import 'package:design_system/src/components/amount/cajui_rolling_amount.dart';
import 'package:design_system/src/components/chart/bar_slot.dart';
import 'package:design_system/src/components/chart/cajui_chart_bar.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/primitives/cajui_springs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A escala do gráfico: pixels por centavo e a altura de cada lado do zero.
typedef _Scale = ({double pixelsPerCent, double above, double below});

/// Mês a mês: uma barra por mês, para cima o que sobrou, para baixo o que
/// faltou, crescendo com mola ao aparecer.
///
/// Um toque escolhe o mês, e o destaque em cima diz o valor por extenso —
/// é o número equivalente em texto que todo gráfico do app exige (RN-862).
/// Cada barra também é um botão com o próprio nome e valor para o leitor de
/// tela, e o mês escolhido é anunciado como "selecionado".
///
/// A falta usa o tom neutro, nunca vermelho: o mês que não fechou é fato. No
/// movimento reduzido as barras já nascem na altura certa.
class CajuiBarChart extends StatefulWidget {
  /// Cria o gráfico das [bars], da mais antiga à mais nova.
  const new({
    required this.bars,
    required this.semanticLabel,
    this.selected,
    this.onSelected,
    super.key,
  });

  /// Os meses, da esquerda para a direita.
  final List<CajuiChartBar> bars;

  /// O que o gráfico mostra: "Mês a mês: o que sobrou ou faltou".
  final String semanticLabel;

  /// O mês em destaque. Sem escolha, o mais recente.
  final int? selected;

  /// Avisa qual mês foi tocado.
  final ValueChanged<int>? onSelected;

  @override
  State<CajuiBarChart> createState() => _CajuiBarChartState();
}

class _CajuiBarChartState extends State<CajuiBarChart>
    with SingleTickerProviderStateMixin {
  static const double _plotHeight = 140;

  /// Cada barra leva 0,6 s para assentar na mola `grow`.
  static const double _growSeconds = 0.6;
  static final _spring = SpringSimulation(CajuiSprings.grow, 0, 1, 0);

  late final AnimationController _grow = AnimationController(vsync: this);
  late int _selected = _initialSelection;
  bool _started = false;

  int get _initialSelection =>
      widget.selected ?? math.max(0, widget.bars.length - 1);

  double get _staggerSeconds =>
      CajuiDurations.stagger.inMicroseconds / Duration.microsecondsPerSecond;

  double get _totalSeconds =>
      _growSeconds + _staggerSeconds * math.max(0, widget.bars.length - 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _growIn();
  }

  @override
  void didUpdateWidget(CajuiBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) _selected = _initialSelection;
    if (!listEquals(widget.bars, oldWidget.bars)) _growIn();
  }

  void _growIn() {
    final animate = CajuiTheme.of(context).motionLevel.allowsSpring;
    if (!animate) {
      _grow.value = 1;
      return;
    }
    final micros = (_totalSeconds * Duration.microsecondsPerSecond).round();
    _grow
      ..duration = Duration(microseconds: micros)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  /// Quanto a barra [index] cresceu: cada uma começa um pouco depois da
  /// anterior e segue a mola, que passa da altura e volta.
  double _growthOf(int index) {
    if (_grow.isCompleted || _grow.value >= 1) return 1;
    final local = _grow.value * _totalSeconds - index * _staggerSeconds;
    return local <= 0 ? 0 : _spring.x(local);
  }

  void _select(int index) {
    setState(() => _selected = index);
    widget.onSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final bars = widget.bars;
    final index = math.min(_selected, math.max(0, bars.length - 1));
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bars.isNotEmpty) _callout(theme, bars[index]),
          const SizedBox(height: CajuiSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) => _plot(constraints.maxWidth),
          ),
        ],
      ),
    );
  }

  /// O destaque: o mês escolhido por extenso, com o valor rolando de um mês
  /// para o outro. Fica fora da leitura de tela porque cada barra já diz o
  /// próprio valor — lido duas vezes, viraria ruído.
  Widget _callout(CajuiThemeData theme, CajuiChartBar bar) {
    final muted = theme.colors.text.muted;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bar.title, style: theme.typography.label.copyWith(color: muted)),
          const SizedBox(height: CajuiSpacing.xs),
          Wrap(
            spacing: CajuiSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                bar.note,
                style: theme.typography.body.copyWith(color: muted),
              ),
              CajuiRollingAmount(
                bar.cents.abs(),
                large: true,
                tone: bar.cents >= 0
                    ? CajuiAmountTone.positive
                    : CajuiAmountTone.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mês apertado não vira barra fina: abaixo de 48 por coluna, o gráfico
  /// rola de lado, começando pelo mês mais novo.
  Widget _plot(double width) {
    final bars = widget.bars;
    if (bars.isEmpty) return const SizedBox(height: _plotHeight);
    final fits =
        width.isFinite && width / bars.length >= CajuiSpacing.touchTarget;
    final slot = fits ? width / bars.length : CajuiSpacing.touchTarget;
    final scale = _scale();
    final row = AnimatedBuilder(
      animation: _grow,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, bar) in bars.indexed)
            _slot(index, bar, slot, scale),
        ],
      ),
    );
    if (fits) return row;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: row,
    );
  }

  /// Uma escala só para todas as barras: a linha do zero fica onde a maior
  /// sobra e a maior falta cabem juntas na altura do gráfico.
  _Scale _scale() {
    final cents = widget.bars.map((bar) => bar.cents);
    final up = math.max(0, cents.reduce(math.max));
    final down = math.max(0, -cents.reduce(math.min));
    final perCent = _plotHeight / math.max(1, up + down);
    return (pixelsPerCent: perCent, above: up * perCent, below: down * perCent);
  }

  Widget _slot(int index, CajuiChartBar bar, double width, _Scale scale) {
    return BarSlot(
      bar: bar,
      width: width,
      scale: scale.pixelsPerCent,
      above: scale.above,
      below: scale.below,
      grow: _growthOf(index),
      selected: index == _selected,
      onPressed: () => _select(index),
    );
  }
}
