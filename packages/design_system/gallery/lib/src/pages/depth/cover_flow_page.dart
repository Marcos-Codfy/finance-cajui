import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_showcase.dart';
import 'package:gallery/src/pages/depth/depth_stage.dart';
import 'package:gallery/src/pages/depth/month_sample.dart';
import 'package:gallery/src/pages/depth/motion_level_chips.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// O carrossel 3D, com os números do mês.
class CoverFlowPage extends StatefulWidget {
  /// Cria a página.
  const new({super.key});

  @override
  State<CoverFlowPage> createState() => _CoverFlowPageState();
}

class _CoverFlowPageState extends State<CoverFlowPage> {
  static const _titles = [
    'Sobra de outubro',
    'O que entra',
    'O que sai do bolso',
    'Vale do mês',
  ];

  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Carrossel 3D',
      lead:
          'Os números do mês num tambor deitado: o do centro de frente, os '
          'vizinhos girando para longe. Arraste de lado ou toque num '
          'vizinho.',
      sections: [
        GallerySection(
          title: 'Os números do mês',
          description:
              'O alto do Início. A altura é a do número mais alto: com fonte '
              'grande, o carrossel cresce em vez de cortar.',
          child: DepthShowcase(stage: _carousel(context), notes: _notes),
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

  /// O carrossel na largura de um celular, com a margem da tela: as
  /// vizinhas aparecem cortadas pela borda, como no Início. Embaixo, a
  /// página em que ele assentou — o que o `onPageChanged` entrega.
  Widget _carousel(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return DepthStage(
      height: null,
      child: Padding(
        padding: const EdgeInsets.all(CajuiSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MonthSample.heading(context, 'Início'),
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
