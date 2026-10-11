import 'package:design_system/src/components/amount/cajui_amount_tone.dart';
import 'package:design_system/src/components/amount/cajui_rolling_amount.dart';
import 'package:design_system/src/components/gauge/water_jar_painter.dart';
import 'package:design_system/src/components/gauge/water_motion.dart';
import 'package:design_system/src/format/brl_formatter.dart';
import 'package:design_system/src/motion/cajui_tilt.dart';
import 'package:design_system/src/motion/frame_clock.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O "pode gastar" como um pote de água: esvazia conforme se gasta e balança
/// quando o celular se mexe.
///
/// É um medidor de progresso (RN-862), então nunca vem sem o número: ao lado
/// do pote ficam o rótulo, o valor — que rola até o certo ao aparecer — e a
/// frase de apoio. O leitor de tela ouve os três, e nada do balanço.
///
/// Água baixando não é bronca: a cor é sempre a da água, e o pote vazio só
/// troca o tom do valor para o da falta, com a frase dizendo o que fazer.
///
/// A água assenta sozinha em cerca de dois segundos e o relógio de quadros
/// dorme — nada aqui se mexe em laço (WCAG 2.2.2). No movimento reduzido o
/// pote é um desenho parado: nível certo, superfície reta, sem inclinação.
class CajuiWaterGauge extends StatefulWidget {
  /// Cria o pote com [fraction] de água e o valor [cents].
  const new({
    required this.fraction,
    required this.cents,
    required this.label,
    this.caption,
    this.tone,
    this.tilt,
    super.key,
  });

  /// Quanto ainda há, de 0 (vazio) a 1 (cheio): o que sobra sobre o limite.
  final double fraction;

  /// O que ainda dá para gastar, em centavos. Negativo quando passou.
  final int cents;

  /// O que o pote mede: "Pode gastar esta semana".
  final String label;

  /// A frase de apoio: "de R$ 400,00 · até domingo".
  final String? caption;

  /// O tom do valor. Sem escolha, é o da sobra — e o da falta se o valor
  /// estiver negativo.
  final CajuiAmountTone? tone;

  /// A inclinação do aparelho, lida pelo app. Sem ela, a água só se mexe
  /// quando o nível muda.
  final CajuiTilt? tilt;

  @override
  State<CajuiWaterGauge> createState() => _CajuiWaterGaugeState();
}

class _CajuiWaterGaugeState extends State<CajuiWaterGauge>
    with SingleTickerProviderStateMixin {
  static const double _jarWidth = 84;
  static const double _jarHeight = 108;

  /// A água nasce vazia e enche até o nível ao aparecer.
  final WaterMotion _water = WaterMotion();
  late final FrameClock _clock = FrameClock(vsync: this, onFrame: _water.step);
  bool _alive = false;

  @override
  void initState() {
    super.initState();
    widget.tilt?.addListener(_onTilt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alive = CajuiTheme.of(context).motionLevel.allowsSpring;
    _follow();
  }

  @override
  void didUpdateWidget(CajuiWaterGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tilt != widget.tilt) {
      oldWidget.tilt?.removeListener(_onTilt);
      widget.tilt?.addListener(_onTilt);
    }
    if (oldWidget.fraction != widget.fraction) _follow();
  }

  /// Leva a água ao nível pedido: com mola e marola, ou de uma vez.
  void _follow() {
    _water.fillTo(widget.fraction);
    if (_alive) {
      _clock.wake();
    } else {
      _clock.sleep();
      _water.settle();
    }
  }

  void _onTilt() {
    final tilt = widget.tilt;
    if (!_alive || tilt == null) return;
    _water.tiltTo(tilt.value.dx);
    _clock.wake();
  }

  @override
  void dispose() {
    widget.tilt?.removeListener(_onTilt);
    _clock.dispose();
    _water.dispose();
    super.dispose();
  }

  String get _spokenValue {
    final amount = BrlFormatter.format(widget.cents);
    final caption = widget.caption;
    return caption == null ? amount : '$amount. $caption';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      container: true,
      label: widget.label,
      value: _spokenValue,
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: _jarWidth,
            height: _jarHeight,
            child: RepaintBoundary(
              child: CustomPaint(painter: _painter(theme)),
            ),
          ),
          const SizedBox(width: CajuiSpacing.xl),
          Expanded(child: _texts(theme)),
        ],
      ),
    );
  }

  WaterJarPainter _painter(CajuiThemeData theme) {
    final colors = theme.colors;
    return WaterJarPainter(
      water: _water,
      liquid: colors.data.water,
      glass: colors.data.track,
      outline: colors.border.field,
      sheen: colors.brand.sheen,
    );
  }

  Widget _texts(CajuiThemeData theme) {
    final muted = theme.colors.text.muted;
    final caption = widget.caption;
    final negative = widget.cents < 0;
    final fallback = negative
        ? CajuiAmountTone.shortfall
        : CajuiAmountTone.positive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.typography.label.copyWith(color: muted),
        ),
        const SizedBox(height: CajuiSpacing.xs),
        CajuiRollingAmount(
          widget.cents,
          from: 0,
          tone: widget.tone ?? fallback,
          large: true,
        ),
        if (caption != null) ...[
          const SizedBox(height: CajuiSpacing.xs),
          Text(caption, style: theme.typography.caption.copyWith(color: muted)),
        ],
      ],
    );
  }
}
