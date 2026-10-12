import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// A página dos componentes de conteúdo: valor, cartão, linha de lista,
/// medidor e indicador de confiança.
///
/// Os números são os do outubro do Início da gallery, para cada página
/// contar a mesma história.
class ContentPage extends StatelessWidget {
  /// Cria a página de conteúdo.
  const new({super.key});

  static const double _cardWidth = 320;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Valores e cartões',
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

  /// O papel de cada tom, em português; o nome da API vem ao lado.
  static String _toneName(CajuiAmountTone tone) => switch (tone) {
    CajuiAmountTone.neutral => 'Neutro',
    CajuiAmountTone.muted => 'Apagado',
    CajuiAmountTone.positive => 'Sobra',
    CajuiAmountTone.shortfall => 'Falta',
    CajuiAmountTone.accent => 'Destaque',
  };

  Widget _amounts() {
    const samples = {
      CajuiAmountTone.neutral: 420000,
      CajuiAmountTone.muted: 3840,
      CajuiAmountTone.positive: 131240,
      CajuiAmountTone.shortfall: -27050,
      CajuiAmountTone.accent: 40000,
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
            child: CajuiAmountText(420000, large: true, hideZeroCents: true),
          ),
          for (final MapEntry(key: tone, value: cents) in samples.entries)
            GallerySpecimen(
              state: _toneName(tone),
              token: tone.name,
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
          _card(context, 'Padrão', 'Sobra de outubro', 131240),
          _card(context, 'Rebaixado', 'Vale do mês', 40000, sunken: true),
          _card(
            context,
            'Tocável',
            'O que sai do bolso',
            288760,
            onPressed: _nothing,
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String state,
    String title,
    int cents, {
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
        child: _cardBody(CajuiTheme.of(context), title, cents),
      ),
    );
  }

  /// O corpo estica até a largura do exemplar: o cartão tocável passa pelo
  /// `CajuiPressable`, que centraliza e afrouxa a largura, e com o corpo
  /// encolhido ele ficava menor que os outros e solto no meio da caixa.
  Widget _cardBody(CajuiThemeData theme, String title, int cents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.xs),
        CajuiAmountText(cents),
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

  /// O limite do Cartão Ipê (R$ 2.000,00), nos degraus da tela de cartões:
  /// livre, metade, acima de 80% e passado. Cartão é forma de pagamento: o
  /// medidor fala de limite em uso, nunca de gasto.
  Widget _meters(BuildContext context) {
    return GallerySection(
      title: 'Medidor',
      description:
          'Passar do limite não pinta alarme: a barra enche, muda para a cor '
          'da falta, e o texto ao lado diz quanto passou.',
      child: GallerySpecimens(
        children: _meterSpecimens(CajuiTheme.of(context).colors),
      ),
    );
  }

  List<Widget> _meterSpecimens(CajuiColors colors) {
    String brl(int cents) => BrlFormatter.format(cents);
    String inUse(int cents) => '${brl(cents)} de ${brl(200000)} em uso';
    final free = colors.intent.positive;
    return [
      _meter('Vazio', 0, 'Nada em uso', free),
      _meter('Em uso', 0.21, inUse(41290), free),
      _meter('Metade', 0.62, inUse(124000)),
      _meter('Acima de 80%', 0.86, inUse(172000), colors.shortfall),
      _meter('Passou do limite', 1.12, 'Passou ${brl(24000)} do limite'),
    ];
  }

  Widget _meter(String state, double value, String reading, [Color? fill]) {
    return GallerySpecimen(
      state: '$state · $reading',
      width: _cardWidth,
      child: CajuiMeter(
        value: value,
        fill: fill,
        semanticLabel: 'Limite do Cartão Ipê',
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
              state: switch (level) {
                CajuiConfidenceLevel.high => 'Alta',
                CajuiConfidenceLevel.medium => 'Média',
                CajuiConfidenceLevel.low => 'Baixa',
              },
              token: level.name,
              child: CajuiConfidenceIndicator(level),
            ),
        ],
      ),
    );
  }
}
