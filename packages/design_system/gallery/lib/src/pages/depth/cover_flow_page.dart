import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_notes.dart';
import 'package:gallery/src/pages/depth/month_sample.dart';
import 'package:gallery/src/pages/depth/motion_level_chips.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// O carrossel 3D, com os números do mês.
class CoverFlowPage extends StatefulWidget {
  /// Cria a página.
  const new({super.key});

  @override
  State<CoverFlowPage> createState() => _CoverFlowPageState();
}

class _CoverFlowPageState extends State<CoverFlowPage> {
  static const _titles = ['Sobra do mês', 'O que entra', 'O que sai', 'Vale'];

  /// A largura de um celular: o carrossel é feito para o polegar.
  static const double _phone = 390;

  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Carrossel 3D',
      lead:
          'Os números do mês num tambor deitado: o do centro de frente, os '
          'vizinhos girando para longe. Arraste de lado, toque num vizinho '
          'ou nos pontos. Cada encaixe tem o deslize e o pulso de tecla — '
          'ligue o som para ouvir.',
      sections: [
        GallerySection(
          title: 'Os números do mês',
          description:
              'O alto do Início. A altura é a do número mais alto: com fonte '
              'grande, o carrossel cresce em vez de cortar.',
          child: GallerySpecimens(
            children: [_carousel(context), const DepthNotes(notes: _notes)],
          ),
        ),
        const GallerySection(
          title: 'Nível de movimento',
          description:
              'No reduzido, as páginas ficam planas, lado a lado, e trocar é '
              'um corte com esmaecer de 120 ms.',
          child: MotionLevelChips(),
        ),
      ],
    );
  }

  /// O carrossel e, embaixo, a página em que ele assentou — o que o
  /// `onPageChanged` entrega a quem usa.
  Widget _carousel(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _phone),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CajuiCoverFlow(
            semanticLabel: 'Números do mês',
            onPageChanged: (page) => setState(() => _page = page),
            children: MonthSample.numbers(),
          ),
          Text(
            'Página ${_page + 1} de 4 · ${_titles[_page]}',
            textAlign: TextAlign.center,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
        ],
      ),
    );
  }

  static const _notes = [
    (
      'Encaixe com mola',
      'Ao soltar, a página assenta com a mola do carrossel: trava que se '
          'sente, quique que não se vê. Um gesto rápido passa uma página só.',
    ),
    (
      'Sem arrastar também se chega',
      'Tocar no vizinho o traz para o centro. Os pontos são um controle só, '
          'de 48 de altura: toque, setas do teclado ou ajuste do leitor de '
          'tela.',
    ),
    (
      'Quem ouve',
      'Cada página começa por "Página 2 de 4". As que estão fora do palco '
          'continuam na leitura, e o foco nelas as traz para o centro.',
    ),
    (
      'A câmera do palco',
      'Os vizinhos fogem para o mesmo ponto, no meio do palco: uma cena só. '
          'O da frente é pintado por cima e é quem recebe o toque.',
    ),
  ];
}
