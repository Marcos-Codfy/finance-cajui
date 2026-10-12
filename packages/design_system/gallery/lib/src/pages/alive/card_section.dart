import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/alive/tilt_pad.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// O cartão em 3D, nos três degraus do limite.
class CardSection extends StatelessWidget {
  /// Cria a seção, ligada à inclinação de mentira [tilt].
  const new({required this.tilt, super.key});

  /// A inclinação de mentira, escrita pelo celular de arrasto (`TiltPad`).
  final ValueNotifier<Offset> tilt;

  /// Cartões fictícios, com nomes de árvore do Cerrado: limite de
  /// R$ 2.000,00 a R$ 3.500,00, em cada degrau do medidor.
  static const _cards = [
    (
      'Abaixo da metade',
      'Cartão Pequi',
      'fecha dia 3 · vence dia 10',
      41290,
      250000,
    ),
    (
      'Acima da metade',
      'Cartão Ipê',
      'fecha dia 25 · vence dia 5',
      124000,
      200000,
    ),
    (
      'Acima de 80%',
      'Cartão Buriti',
      'fecha dia 12 · vence dia 20',
      301050,
      350000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Cartão em 3D',
      description:
          'Inclina com o celular e com o arrasto de lado — o de cima para '
          'baixo continua rolando a tela —, e o brilho anda ao contrário, '
          'como luz de teto. Um toque vira o cartão e mostra o limite: a '
          'barra muda de tom na metade e nos 80%, e a frase descreve o fato, '
          'sem alarme. Cartão é forma de pagamento — nada aqui diz "gasto".',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TiltPad(tilt: tilt),
          const SizedBox(height: CajuiSpacing.xxl),
          GallerySpecimens(children: [for (final card in _cards) _card(card)]),
        ],
      ),
    );
  }

  Widget _card((String, String, String, int, int) card) {
    final (state, name, detail, used, limit) = card;
    return GallerySpecimen(
      state: state,
      width: 320,
      child: CajuiCreditCard3D(
        name: name,
        detail: detail,
        usedCents: used,
        limitCents: limit,
        tilt: tilt,
      ),
    );
  }
}
