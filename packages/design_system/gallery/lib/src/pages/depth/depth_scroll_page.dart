import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_showcase.dart';
import 'package:gallery/src/pages/depth/depth_stage.dart';
import 'package:gallery/src/pages/depth/month_sample.dart';
import 'package:gallery/src/pages/depth/motion_level_chips.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A rolagem em profundidade, num aparelho de verdade.
class DepthScrollPage extends StatelessWidget {
  /// Cria a página.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Rolagem em profundidade',
      lead:
          'A tela como a face de um tambor: plana no meio, curvando para '
          'longe nas bordas. O que entra por baixo vem deitado e assenta; o '
          'que sai por cima recua e é coberto pelo seguinte. Role dentro do '
          'aparelho.',
      sections: [
        _live(context),
        const GallerySection(
          title: 'Nível de movimento',
          description:
              'No leve, a borda curva sem esmaecer. No reduzido, é uma lista '
              'comum: plana, parada, e o fundo não anda.',
          child: MotionLevelChips(),
        ),
      ],
    );
  }

  Widget _live(BuildContext context) {
    return GallerySection(
      title: 'Ao vivo',
      description:
          'O Início de outubro. Puxe além do topo: a superfície quica, e o '
          'halo do fundo desce junto, mais devagar.',
      child: DepthShowcase(
        notes: _notes,
        stage: DepthStage(
          child: CajuiDepthScroll(
            backdrop: MonthSample.backdrop(context),
            children: _screen(context),
          ),
        ),
      ),
    );
  }

  static const _notes = [
    (
      'Inteiro à vista, plano',
      'Só curva o que está cortado pela borda. O que se lê nunca treme '
          'embaixo do olho.',
    ),
    (
      'A faixa da borda',
      'Um terço da altura da tela, no máximo a altura do próprio bloco. '
          'Bloco comprido só curva quando sobra dele menos que a faixa.',
    ),
    (
      'Duas camadas de paralaxe',
      'O bloco que entra sobe mais devagar que a lista; o fundo, a um terço '
          'da velocidade.',
    ),
    (
      'Custo por quadro',
      'Rolar só troca matrizes. Nada é remontado nem medido de novo, e cada '
          'seção é pintada uma vez e reaproveitada.',
    ),
  ];

  static List<Widget> _screen(BuildContext context) => [
    MonthSample.heading(context, 'Início'),
    ...MonthSample.numbers(),
    const CajuiSectionTitle('Minhas contas'),
    MonthSample.rows(MonthSample.bills),
    const SizedBox(height: CajuiSpacing.xl),
    const CajuiSectionTitle('Últimos lançamentos'),
    MonthSample.rows(MonthSample.entries),
    const SizedBox(height: CajuiSpacing.xl),
    const CajuiSectionTitle('Mês a mês'),
    MonthSample.rows(const [
      ('Setembro', 'sobrou', 31200),
      ('Agosto', 'sobrou', 8450),
      ('Julho', 'faltou', 12300),
    ]),
  ];
}
