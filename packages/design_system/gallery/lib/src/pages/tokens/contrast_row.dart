import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma linha da tabela de contraste: a amostra, o par, a exigência e a razão.
class ContrastRow extends StatelessWidget {
  /// Cria a linha do par [pair].
  const new(this.pair, {super.key});

  /// O par medido.
  final ContrastPair pair;

  static const double _sampleWidth = 64;
  static const double _ratioWidth = 72;

  String get _ratio => '${pair.ratio.toStringAsFixed(2)}:1';

  String get _verdict => pair.passes ? 'passa' : 'falha';

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      label:
          '${pair.foregroundName} sobre ${pair.backgroundName}: $_ratio, '
          'mínimo ${pair.requirement.minimum}, $_verdict',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CajuiSpacing.xs),
        child: Row(
          children: [
            _sample(theme),
            const SizedBox(width: CajuiSpacing.md),
            Expanded(child: _names(theme)),
            SizedBox(width: _ratioWidth, child: _ratioText(theme)),
            _verdictMark(theme),
          ],
        ),
      ),
    );
  }

  Widget _sample(CajuiThemeData theme) {
    return Container(
      width: _sampleWidth,
      height: CajuiSpacing.touchTarget - CajuiSpacing.sm,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: const BorderRadius.all(CajuiRadius.xs),
        border: Border.all(color: theme.colors.border.subtle),
      ),
      child: Text(
        'Aa',
        style: theme.typography.bodyStrong.copyWith(color: pair.foreground),
      ),
    );
  }

  Widget _names(CajuiThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${pair.foregroundName} sobre ${pair.backgroundName}',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
        Text(
          '${pair.requirement.label} · mínimo ${pair.requirement.minimum}:1',
          style: theme.typography.caption.copyWith(
            color: theme.colors.text.faint,
          ),
        ),
      ],
    );
  }

  Widget _ratioText(CajuiThemeData theme) {
    return Text(
      _ratio,
      textAlign: TextAlign.end,
      style: theme.typography.amount.copyWith(color: theme.colors.text.primary),
    );
  }

  /// O veredito vem escrito e com ícone: cor nunca é o único sinal.
  Widget _verdictMark(CajuiThemeData theme) {
    final intent = theme.colors.intent;
    final color = pair.passes ? intent.positive : intent.danger;
    return Padding(
      padding: const EdgeInsets.only(left: CajuiSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CajuiIcon(
            pair.passes ? CajuiIconData.check : CajuiIconData.close,
            size: 16,
            color: color,
          ),
          const SizedBox(width: CajuiSpacing.xs),
          Text(_verdict, style: theme.typography.label.copyWith(color: color)),
        ],
      ),
    );
  }
}
