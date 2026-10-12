import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// As famílias de toque, em controles de verdade: cada um soa do seu jeito
/// (`CajuiTouch`), pelo mesmo caminho do app — a resposta de interação, e
/// não o tocador direto da mesa. Por isso só soam com o som ligado.
class TouchFamilies extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<TouchFamilies> createState() => _TouchFamiliesState();
}

class _TouchFamiliesState extends State<TouchFamilies> {
  static const double _width = 280;

  bool _chipOn = false;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Famílias de toque',
      description:
          'Ligue "Som nas interações" e toque: o botão de ação dá o clique '
          '(tap); o card — cartão, linha, opção — dá o pop, mais leve (card); '
          'cada tecla num campo dá um tique (key); e o chip soa como chave, '
          'subindo ao ligar e descendo ao desligar.',
      child: GallerySpecimens(children: _specimens(context)),
    );
  }

  List<Widget> _specimens(BuildContext context) => [
    GallerySpecimen(
      state: 'Botão de ação · sound.tap',
      child: CajuiButton(label: 'Salvar lançamento', onPressed: _nothing),
    ),
    GallerySpecimen(
      state: 'Card · sound.card',
      width: _width,
      child: _card(CajuiTheme.of(context)),
    ),
    const GallerySpecimen(
      state: 'Campo de texto · sound.key',
      width: _width,
      child: CajuiTextField(
        label: 'Escreva algo',
        hint: 'Cada tecla, um tique',
      ),
    ),
    GallerySpecimen(
      state: 'Chip · sound.toggleOn e toggleOff',
      child: CajuiChip(
        label: 'Mercado',
        selected: _chipOn,
        onSelected: (on) => setState(() => _chipOn = on),
      ),
    ),
  ];

  Widget _card(CajuiThemeData theme) {
    return CajuiCard(
      onPressed: _nothing,
      semanticLabel: 'Sobra de outubro',
      // Esticado até a largura do exemplar, como os cartões de Valores e
      // cartões: o tocável não encolhe dentro da caixa.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sobra de outubro',
            style: theme.typography.label.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
          const SizedBox(height: CajuiSpacing.xs),
          const CajuiAmountText(131240, tone: CajuiAmountTone.positive),
        ],
      ),
    );
  }
}
