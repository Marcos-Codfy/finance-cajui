import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// Um estilo da escala, com o nome do token e uma frase de exemplo.
typedef _TypeSample = ({String token, TextStyle style, String sample});

/// A página de tipografia: a escala inteira, com frases na voz da marca.
class TypographyPage extends StatelessWidget {
  /// Cria a página de tipografia.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final type = CajuiTheme.of(context).typography;
    return GalleryPage(
      title: 'Tipografia',
      lead:
          'Fraunces dá a voz — títulos e números-manchete. Geist faz o '
          'trabalho: leitura, rótulos e valores em algarismos tabulares.',
      sections: [
        _scale('Títulos · Fraunces', _display(type)),
        _scale('Leitura · Geist', _reading(type)),
        _scale(
          'Valores · algarismos tabulares',
          _amounts(type),
          note:
              'Todos os algarismos têm a mesma largura: o número não treme '
              'quando conta, e as colunas alinham sozinhas.',
        ),
      ],
    );
  }

  List<_TypeSample> _display(CajuiTypography t) => [
    (token: 'displayLarge', style: t.displayLarge, sample: 'Sobra de outubro'),
    (token: 'displayMedium', style: t.displayMedium, sample: 'O mês até aqui'),
    (token: 'headline', style: t.headline, sample: 'Outubro'),
    (token: 'title', style: t.title, sample: 'Seu dinheiro'),
  ];

  List<_TypeSample> _reading(CajuiTypography t) => [
    (
      token: 'body',
      style: t.body,
      sample: 'Outubro fecha com sobra. Dá para o mercado de sábado.',
    ),
    (token: 'bodyStrong', style: t.bodyStrong, sample: 'Confere se é isso?'),
    (token: 'label', style: t.label, sample: 'Salvar lançamento'),
    (token: 'caption', style: t.caption, sample: 'Pago no vale alimentação'),
    (token: 'overline', style: t.overline, sample: 'OUTUBRO DE 2026'),
  ];

  List<_TypeSample> _amounts(CajuiTypography t) => [
    (
      token: 'amountLarge',
      style: t.amountLarge,
      sample: BrlFormatter.format(131240),
    ),
    (token: 'amount', style: t.amount, sample: BrlFormatter.format(312000)),
    (token: 'amount', style: t.amount, sample: BrlFormatter.format(111111)),
  ];

  Widget _scale(String title, List<_TypeSample> samples, {String? note}) {
    return GallerySection(
      title: title,
      description: note,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final sample in samples) _SampleRow(sample)],
      ),
    );
  }
}

class _SampleRow extends StatelessWidget {
  const new(this.sample);

  final _TypeSample sample;

  /// Família, corpo sobre entrelinha e peso, lidos do próprio estilo — se o
  /// token mudar, a legenda muda junto.
  String get _spec {
    final style = sample.style;
    final family = (style.fontFamily ?? '').split('/').last;
    final size = style.fontSize ?? 0;
    final line = (size * (style.height ?? 1)).round();
    final weight = style.fontVariations
        ?.where((variation) => variation.axis == 'wght')
        .firstOrNull
        ?.value
        .round();
    return '$family · ${size.round()}/$line · peso ${weight ?? 400}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sample.token} · $_spec',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
          const SizedBox(height: CajuiSpacing.xs),
          Text(
            sample.sample,
            style: sample.style.copyWith(color: theme.colors.text.primary),
          ),
        ],
      ),
    );
  }
}
