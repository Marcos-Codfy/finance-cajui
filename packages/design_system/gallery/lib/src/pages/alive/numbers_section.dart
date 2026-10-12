import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// O número que rola até o valor e voa do Início para o Meu mês, como no
/// app (escolha 3 do dono).
class NumbersSection extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<NumbersSection> createState() => _NumbersSectionState();
}

class _NumbersSectionState extends State<NumbersSection> {
  static const _tag = 'gallery-month-result';
  int _run = 0;

  void _openDetail() {
    Navigator.of(
      context,
    ).push(CajuiPageRoute<void>(builder: (_) => const _MonthDetail(tag: _tag)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return GallerySection(
      title: 'Números que rolam e voam',
      description:
          'O número rola do zero até o valor ao aparecer, e o leitor de tela '
          'ouve só o valor final. Abrindo o Meu mês, a sobra sai do cartão e '
          'cresce até o alto da tela nova: o olho não precisa procurá-la de '
          'novo. No movimento reduzido, o número nasce pronto e a tela troca '
          'com a fusão curta de sempre.',
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
          label: 'Abrir o Meu mês',
          size: CajuiButtonSize.compact,
          onPressed: _openDetail,
        ),
        CajuiButton(
          label: 'Rolar de novo',
          size: CajuiButtonSize.compact,
          variant: CajuiButtonVariant.secondary,
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
          'Sobra de outubro',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.xs),
        CajuiHeroNumber(
          tag: _tag,
          child: CajuiRollingAmount(
            HomeNumbers.leftover,
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

/// O Meu mês de mentira, onde a sobra pousa.
class _MonthDetail extends StatelessWidget {
  const new({required this.tag});

  final String tag;

  static String _brl(int cents) => BrlFormatter.format(cents);

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Meu mês',
      overline: 'Outubro de 2026',
      onBack: () => Navigator.of(context).pop(),
      children: [
        CajuiHeroNumber(
          tag: tag,
          child: Text(
            _brl(HomeNumbers.leftover),
            style: theme.typography.displayLarge.copyWith(
              color: theme.colors.intent.positive,
            ),
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Text(
          'Sobra de outubro. Entra ${_brl(HomeNumbers.income)}; sai do '
          'bolso ${_brl(HomeNumbers.outOfPocket)}, já com o vale cobrindo o '
          'mercado.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
      ],
    );
  }
}
