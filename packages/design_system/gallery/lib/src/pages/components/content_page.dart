import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// A página dos componentes de conteúdo: valor, cartão, linha de lista,
/// medidor e indicador de confiança.
///
/// Os números são os do exemplo único da especificação (setembro de 2026),
/// para a gallery contar a mesma história que os documentos.
class ContentPage extends StatelessWidget {
  /// Cria a página de conteúdo.
  const new({super.key});

  static const double _cardWidth = 320;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Conteúdo',
      lead:
          'Onde o dinheiro aparece. O valor é sempre texto de verdade, com '
          'algarismos tabulares; gráfico só onde há parte e todo.',
      sections: [
        _amounts(),
        _cards(context),
        _rows(),
        _meters(context),
        _confidence(),
      ],
    );
  }

  Widget _amounts() {
    const samples = {
      CajuiAmountTone.neutral: 19600,
      CajuiAmountTone.muted: 3840,
      CajuiAmountTone.positive: 55800,
      CajuiAmountTone.shortfall: -12000,
      CajuiAmountTone.accent: 65000,
    };
    return GallerySection(
      title: 'Valor',
      description:
          'O tom diz o papel do número, não se ele é bom ou ruim. A falta '
          'usa o sinal de menos tipográfico e a cor em avaliação.',
      child: GallerySpecimens(
        children: [
          const GallerySpecimen(
            state: 'Manchete',
            child: CajuiAmountText(55800, large: true, hideZeroCents: true),
          ),
          for (final MapEntry(key: tone, value: cents) in samples.entries)
            GallerySpecimen(
              state: tone.name,
              child: CajuiAmountText(cents, tone: tone),
            ),
        ],
      ),
    );
  }

  Widget _cards(BuildContext context) {
    return GallerySection(
      title: 'Cartão',
      description:
          'O tocável levanta no mouse e encolhe no toque; o rebaixado agrupa '
          'sem competir com o que está por cima.',
      child: GallerySpecimens(
        children: [
          _card(context, 'Padrão', 'Sobra de setembro'),
          _card(context, 'Rebaixado', 'Vale alimentação', sunken: true),
          _card(context, 'Tocável', 'Fatura de outubro', onPressed: _nothing),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String state,
    String title, {
    bool sunken = false,
    VoidCallback? onPressed,
  }) {
    return GallerySpecimen(
      state: state,
      width: _cardWidth,
      child: CajuiCard(
        sunken: sunken,
        onPressed: onPressed,
        semanticLabel: onPressed == null ? null : title,
        child: _cardBody(CajuiTheme.of(context), title),
      ),
    );
  }

  Widget _cardBody(CajuiThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.xs),
        const CajuiAmountText(55800),
      ],
    );
  }

  Widget _rows() {
    return GallerySection(
      title: 'Linha de lista',
      description:
          'O título é o que foi comprado; o subtítulo, por onde foi pago. '
          'Cartão de crédito nunca aparece como despesa.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: CajuiCard(
          child: Column(
            children: [
              _row('Mercado', 'Vale alimentação', CajuiIconData.voucher, 3840),
              _row('Farmácia', 'Crédito · 2 de 3', CajuiIconData.card, 4590),
              _row('Corrida de app', 'Pix', CajuiIconData.wallet, 1870),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String what, String paidWith, CajuiIconData icon, int cents) {
    return CajuiListRow(
      title: what,
      subtitle: paidWith,
      leading: CajuiIcon(icon, size: 20),
      trailing: CajuiAmountText(cents),
      onPressed: _nothing,
      semanticLabel: '$what, $paidWith, ${BrlFormatter.format(cents)}',
    );
  }

  Widget _meters(BuildContext context) {
    final data = CajuiTheme.of(context).colors.data;
    final used = BrlFormatter.format(18000);
    final limit = BrlFormatter.format(19600);
    final over = BrlFormatter.format(2375);
    return GallerySection(
      title: 'Medidor',
      description:
          'Passar do limite não pinta alarme: a barra enche, muda para a cor '
          'da falta, e o texto ao lado diz quanto passou.',
      child: GallerySpecimens(
        children: [
          _meter('Vazio', 0, 'Nada gasto', data.variable),
          _meter('Em uso', 0.52, '52% da renda comprometida', data.fixed),
          _meter('Quase no limite', 0.92, '$used de $limit', null),
          _meter('Passou do limite', 1.12, 'Passou $over do limite', null),
        ],
      ),
    );
  }

  Widget _meter(String state, double value, String reading, Color? fill) {
    return GallerySpecimen(
      state: '$state · $reading',
      width: _cardWidth,
      child: CajuiMeter(
        value: value,
        fill: fill,
        semanticLabel: 'Limite da semana',
        semanticValue: reading,
      ),
    );
  }

  Widget _confidence() {
    return GallerySection(
      title: 'Indicador de confiança',
      description:
          'Quanto o app confia na leitura do comprovante. Os pontos vêm '
          'sempre com a frase: confiança baixa vira pergunta, não palpite.',
      child: GallerySpecimens(
        children: [
          for (final level in CajuiConfidenceLevel.values)
            GallerySpecimen(
              state: level.name,
              child: CajuiConfidenceIndicator(level),
            ),
        ],
      ),
    );
  }
}
