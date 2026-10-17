import 'package:design_system/src/components/amount/cajui_amount_text.dart';
import 'package:design_system/src/components/timeline/cajui_timeline_item.dart';
import 'package:design_system/src/components/timeline/cajui_timeline_mark.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// A linha do tempo (17/10/2026): pontos ligados por um traço, de cima para
/// baixo na ordem do dia — o ponto cheio é o feito, o vazio o por fazer, e
/// o do dia que passou ganha o tom de falta. A frase de cada item diz o
/// mesmo em palavras, para quem não vê a cor.
class CajuiTimeline extends StatelessWidget {
  /// Cria a linha com [items], já em ordem.
  const new({required this.items, super.key});

  /// Os itens, do primeiro ao último.
  final List<CajuiTimelineItem> items;

  static const double _dot = 12;
  static const double _rail = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, item) in items.indexed)
        _row(context, item, last: index == items.length - 1),
    ],
  );

  Widget _row(
    BuildContext context,
    CajuiTimelineItem item, {
    required bool last,
  }) {
    final theme = CajuiTheme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CajuiSpacing.md,
        children: [
          _marker(theme.colors, item.mark, last: last),
          Expanded(child: _texts(theme, item)),
          CajuiAmountText(item.cents),
        ],
      ),
    );
  }

  static Widget _texts(CajuiThemeData theme, CajuiTimelineItem item) => Padding(
    padding: const EdgeInsets.only(bottom: CajuiSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: theme.typography.body),
        Text(
          item.subtitle,
          style: theme.typography.caption.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
      ],
    ),
  );

  static Widget _point(Color fill, Color ring) => Container(
    width: _dot,
    height: _dot,
    margin: const EdgeInsets.only(top: CajuiSpacing.xs),
    decoration: BoxDecoration(
      color: fill,
      shape: BoxShape.circle,
      border: Border.all(color: ring, width: _rail),
    ),
  );

  /// O ponto e o traço até o próximo.
  static Widget _marker(
    CajuiColors colors,
    CajuiTimelineMark mark, {
    required bool last,
  }) {
    final (fill, ring) = switch (mark) {
      CajuiTimelineMark.done => (
        colors.intent.positive,
        colors.intent.positive,
      ),
      CajuiTimelineMark.pending => (colors.surface.base, colors.text.faint),
      CajuiTimelineMark.late => (colors.shortfall, colors.shortfall),
    };
    return SizedBox(
      width: _dot,
      child: Column(
        children: [
          _point(fill, ring),
          if (!last)
            Expanded(
              child: Container(width: _rail, color: colors.border.subtle),
            ),
        ],
      ),
    );
  }
}
