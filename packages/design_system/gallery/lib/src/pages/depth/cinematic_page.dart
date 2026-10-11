import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_showcase.dart';
import 'package:gallery/src/pages/depth/depth_stage.dart';
import 'package:gallery/src/pages/depth/month_sample.dart';
import 'package:gallery/src/pages/depth/motion_level_chips.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A entrada cinematográfica: o Início abrindo, com a rolagem em
/// profundidade e o carrossel juntos — o que o app monta.
class CinematicPage extends StatefulWidget {
  /// Cria a página.
  const new({super.key});

  @override
  State<CinematicPage> createState() => _CinematicPageState();
}

class _CinematicPageState extends State<CinematicPage> {
  /// Cada toque em "Rodar de novo" é uma tomada nova.
  int _take = 0;

  void _replay() => setState(() => _take++);

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Entrada cinematográfica',
      lead:
          'O travelling de câmera quando a tela abre: os blocos chegam da '
          'profundidade em cascata, de fora de foco para nítidos, assentam '
          'com mola, e uma faixa de luz cruza a tela uma vez. Tudo em 600 ms.',
      sections: [_live(context), _levels()],
    );
  }

  Widget _live(BuildContext context) {
    return GallerySection(
      title: 'Ao vivo',
      description:
          'Roda uma vez por montagem, e de novo só quando a chave muda — no '
          'app, o mês. Nunca em laço.',
      child: DepthShowcase(
        notes: _notes,
        stage: DepthStage(
          child: CajuiCinematicEntrance(
            replayKey: _take,
            child: CajuiDepthScroll(
              backdrop: MonthSample.backdrop(context),
              children: _shots(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levels() {
    return GallerySection(
      title: 'Nível de movimento',
      description:
          'No leve, sem desfoque e sem luz: só a viagem. No reduzido, os '
          'blocos esmaecem juntos, em 120 ms, já no lugar.',
      child: MotionLevelChips(
        action: CajuiButton(
          label: 'Rodar de novo',
          size: CajuiButtonSize.compact,
          onPressed: _replay,
        ),
      ),
    );
  }

  List<Widget> _shots(BuildContext context) {
    final blocks = [
      MonthSample.heading(context, 'Início'),
      CajuiCoverFlow(
        semanticLabel: 'Números do mês',
        children: MonthSample.numbers(),
      ),
      const SizedBox(height: CajuiSpacing.lg),
      const CajuiSectionTitle('Minhas contas'),
      MonthSample.rows(MonthSample.bills),
      const SizedBox(height: CajuiSpacing.xl),
      const CajuiSectionTitle('Últimos lançamentos'),
      MonthSample.rows(MonthSample.entries),
    ];
    return [
      for (final (index, block) in blocks.indexed)
        CajuiCinematicShot(index: index, child: block),
    ];
  }

  static const _notes = [
    (
      'Opacidade, depois foco',
      'O olho vê que há algo antes de ler o quê; o foco chega antes do fim '
          'do movimento, para nenhum número ficar borrado mais que um '
          'instante.',
    ),
    (
      'Cascata dentro do teto',
      'Cada bloco sai 35 ms depois do anterior; do sexto em diante, todos '
          'juntos. A cena inteira cabe nos 600 ms.',
    ),
    (
      'A luz',
      'Uma faixa rasante, que só cruza depois de os blocos quase assentarem, '
          'nunca mais forte que o brilho do cartão (12%).',
    ),
    (
      'Só quando se vê',
      'Montada atrás de outra aba, a entrada espera a tela aparecer. Quem '
          'usa leitor de tela acha os blocos desde o primeiro quadro.',
    ),
  ];
}
