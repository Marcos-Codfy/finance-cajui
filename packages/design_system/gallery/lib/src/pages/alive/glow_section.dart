import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// O brilho do mês que fecha no verde — e o silêncio do mês que não fecha.
class GlowSection extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<GlowSection> createState() => _GlowSectionState();
}

class _GlowSectionState extends State<GlowSection> {
  /// Valores fictícios de setembro: com falta e com sobra.
  static const int _short = -2375;
  static const int _spare = 22110;
  bool _green = false;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Mês no verde',
      description:
          'Quando o mês passa a fechar com sobra, um halo cresce, faíscas de '
          'capim dourado sobem uma vez e tudo assenta num brilho calmo. '
          'Quando falta, nada brilha e nada toca: a frase diz o que fazer. Fora '
          'do nível completo de movimento, o halo só aparece.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _choice(),
            const SizedBox(height: CajuiSpacing.xxl),
            CajuiGlow(
              active: _green,
              child: CajuiCard(child: _month()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice() {
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        CajuiChip(
          label: 'Faltou',
          selected: !_green,
          onSelected: (_) => setState(() => _green = false),
        ),
        CajuiChip(
          label: 'Fechou no verde',
          selected: _green,
          onSelected: (_) => setState(() => _green = true),
        ),
      ],
    );
  }

  Widget _month() {
    final theme = CajuiTheme.of(context);
    final muted = theme.colors.text.muted;
    final cents = _green ? _spare : _short;
    final sentence = _green
        ? 'Sobraram ${BrlFormatter.format(_spare)} em setembro.'
        : 'Faltam ${BrlFormatter.format(-_short)} para fechar setembro.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Setembro', style: theme.typography.label.copyWith(color: muted)),
        const SizedBox(height: CajuiSpacing.xs),
        CajuiRollingAmount(
          cents,
          tone: _green ? CajuiAmountTone.positive : CajuiAmountTone.shortfall,
          large: true,
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Text(sentence, style: theme.typography.caption.copyWith(color: muted)),
      ],
    );
  }
}
