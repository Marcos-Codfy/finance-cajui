import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// O número que rola até o valor e voa do Início para o detalhe.
class NumbersSection extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<NumbersSection> createState() => _NumbersSectionState();
}

class _NumbersSectionState extends State<NumbersSection> {
  static const _tag = 'gallery-week-left';
  int _run = 0;

  void _openDetail() {
    Navigator.of(
      context,
    ).push(CajuiPageRoute<void>(builder: (_) => const _WeekDetail(tag: _tag)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return GallerySection(
      title: 'Números que rolam e voam',
      description:
          'O número rola do zero até o valor ao aparecer, e o leitor de tela '
          'ouve só o valor final. Abrindo o detalhe, ele sai do cartão e '
          'cresce até o título da tela nova. No movimento reduzido, o número '
          'nasce pronto e a tela troca com a fusão curta de sempre.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CajuiCard(child: _number(theme)),
            const SizedBox(height: CajuiSpacing.md),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        CajuiButton(
          label: 'Abrir o detalhe',
          size: CajuiButtonSize.compact,
          onPressed: _openDetail,
        ),
        CajuiButton(
          label: 'Rolar de novo',
          size: CajuiButtonSize.compact,
          variant: CajuiButtonVariant.ghost,
          onPressed: () => setState(() => _run++),
        ),
      ],
    );
  }

  Widget _number(CajuiThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pode gastar esta semana',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.xs),
        CajuiHeroNumber(
          tag: _tag,
          child: CajuiRollingAmount(
            21200,
            key: ValueKey(_run),
            from: 0,
            tone: CajuiAmountTone.positive,
            large: true,
          ),
        ),
      ],
    );
  }
}

/// A tela de detalhe de mentira, onde o número pousa.
class _WeekDetail extends StatelessWidget {
  const new({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Esta semana',
      onBack: () => Navigator.of(context).pop(),
      children: [
        CajuiHeroNumber(
          tag: tag,
          child: Text(
            BrlFormatter.format(21200),
            style: theme.typography.displayLarge.copyWith(
              color: theme.colors.intent.positive,
            ),
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Text(
          r'de R$ 400,00 até domingo. Mercado, farmácia e transporte já '
          'estão descontados.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
      ],
    );
  }
}
