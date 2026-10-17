import 'dart:math' as math;

import 'package:design_system/src/components/amount/cajui_amount_text.dart';
import 'package:design_system/src/components/chart/cajui_ring_slice.dart';
import 'package:design_system/src/format/brl_formatter.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O anel de para onde foi o dinheiro (17/10/2026): uma fatia por grupo, o
/// total no meio e, embaixo, a legenda — que é por onde o leitor de tela
/// e o dedo escolhem uma fatia. Tocar a fatia no anel também escolhe.
class CajuiRingChart extends StatelessWidget {
  /// Cria o anel de [slices], com [total] no meio.
  const new({
    required this.slices,
    required this.total,
    required this.centerLabel,
    this.selected,
    this.onSelected,
    super.key,
  });

  /// As fatias, na ordem do anel.
  final List<CajuiRingSlice> slices;

  /// O valor do meio, em centavos.
  final int total;

  /// O que o valor do meio é: "Sai no mês".
  final String centerLabel;

  /// A fatia escolhida, que se destaca.
  final int? selected;

  /// Avisa a fatia tocada.
  final ValueChanged<int>? onSelected;

  static const double _size = 200;
  static const double _stroke = 22;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CajuiSpacing.lg,
    children: [
      Center(child: ExcludeSemantics(child: _ring(context))),
      for (final (index, slice) in slices.indexed)
        if (slice.cents > 0) _legend(context, index, slice),
    ],
  );

  Widget _ring(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return GestureDetector(
      onTapUp: (details) => _hit(details.localPosition),
      child: SizedBox.square(
        dimension: _size,
        child: CustomPaint(
          painter: _RingPainter(
            slices: slices,
            selected: selected,
            track: theme.colors.data.track,
            stroke: _stroke,
          ),
          child: Center(child: _middle(theme)),
        ),
      ),
    );
  }

  /// O total, no meio do anel.
  Widget _middle(CajuiThemeData theme) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        centerLabel,
        style: theme.typography.caption.copyWith(
          color: theme.colors.text.muted,
        ),
      ),
      CajuiAmountText(total),
    ],
  );

  /// A fatia sob o toque em [at], pelo ângulo a partir do alto.
  void _hit(Offset at) {
    final pick = onSelected;
    final sum = _sum;
    if (pick == null || sum <= 0) return;
    const center = Offset(_size / 2, _size / 2);
    final turn =
        (math.atan2(at.dy - center.dy, at.dx - center.dx) + math.pi / 2) %
        (2 * math.pi);
    var start = 0.0;
    for (final (index, slice) in slices.indexed) {
      if (slice.cents <= 0) continue;
      start += slice.cents / sum * 2 * math.pi;
      if (turn <= start) return pick(index);
    }
  }

  int get _sum =>
      slices.fold(0, (sum, slice) => sum + math.max(0, slice.cents));

  Widget _legend(BuildContext context, int index, CajuiRingSlice slice) {
    final theme = CajuiTheme.of(context);
    final share = _sum <= 0 ? 0 : (slice.cents * 100 / _sum).round();
    final chosen = index == selected;
    return CajuiPressable(
      onPressed: onSelected == null ? null : () => onSelected!(index),
      selected: chosen,
      semanticLabel:
          '${slice.label}, ${BrlFormatter.format(slice.cents)}, $share%',
      builder: (context, _) => Row(
        spacing: CajuiSpacing.md,
        children: [
          _dot(slice.color, chosen: chosen),
          // A parte vai junto do nome: com a fonte grande, nome, parte e
          // valor lado a lado não cabiam num celular estreito.
          Expanded(
            child: Text(
              '${slice.label} · $share%',
              style: theme.typography.body,
            ),
          ),
          CajuiAmountText(slice.cents),
        ],
      ),
    );
  }
}

/// A bolinha da cor da fatia; a escolhida, maior.
Widget _dot(Color color, {required bool chosen}) => SizedBox.square(
  dimension: chosen ? 14 : 10,
  child: DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  ),
);

class _RingPainter extends CustomPainter {
  const new({
    required this.slices,
    required this.selected,
    required this.track,
    required this.stroke,
  });

  final List<CajuiRingSlice> slices;
  final int? selected;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2 + 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(ring, 0, 2 * math.pi, false, paint..color = track);
    final sum = slices.fold(0, (s, slice) => s + math.max(0, slice.cents));
    if (sum <= 0) return;
    var start = -math.pi / 2;
    for (final (index, slice) in slices.indexed) {
      if (slice.cents <= 0) continue;
      final sweep = slice.cents / sum * 2 * math.pi;
      final chosen = index == selected;
      paint
        ..color = slice.color
        ..strokeWidth = chosen ? stroke + 8 : stroke;
      // Um fio de folga entre as fatias, para cada uma se ler sozinha.
      canvas.drawArc(
        ring,
        start + 0.02,
        math.max(0, sweep - 0.04),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.slices != slices || old.selected != selected || old.track != track;
}
