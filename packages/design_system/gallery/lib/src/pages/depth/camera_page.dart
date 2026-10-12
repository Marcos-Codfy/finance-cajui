import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_showcase.dart';
import 'package:gallery/src/pages/depth/motion_level_chips.dart';
import 'package:gallery/src/pages/depth/orbit_stage.dart';
import 'package:gallery/src/pages/depth/route_stage.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A câmera entre telas: abrir uma tela é a câmera avançando
/// (`CajuiPageRoute`), e trocar de aba é a câmera orbitando
/// (`CajuiOrbitStack`). As duas poses saem de `CameraMove`, com a mesma
/// lente de todo o 3D (ADR-028).
class CameraPage extends StatelessWidget {
  /// Cria a página.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const GalleryPage(
      title: 'Câmera entre telas',
      lead:
          'A troca de tela deixa de ser um corte e vira um movimento de '
          'câmera. É uma passagem, e não uma mistura: em nenhum instante as '
          'duas telas aparecem juntas, uma através da outra.',
      sections: _sections,
    );
  }

  static const List<Widget> _sections = [
    GallerySection(
      title: 'Abrir uma tela',
      description:
          'Toque em "Abrir o Meu mês", ou numa das linhas, dentro do '
          'celular. Para voltar, a seta no alto da tela nova.',
      child: DepthShowcase(stage: RouteStage(), notes: _route),
    ),
    GallerySection(
      title: 'Trocar de aba',
      description:
          'Conte numa aba, troque pela barra do pé e volte: o contador '
          'continua onde estava.',
      child: DepthShowcase(stage: OrbitStage(), notes: _orbit),
    ),
    GallerySection(
      title: 'Nível de movimento',
      description:
          'No leve, sem giro: a tela nova só desliza de baixo, e a aba só '
          'desliza de lado. No reduzido, sobra a passagem de opacidade — a '
          'troca continua perceptível, e nada se desloca.',
      child: MotionLevelChips(),
    ),
  ];

  static const _route = [
    (
      'A de trás recua e some',
      'No primeiro terço da troca, a tela de trás encolhe um pouco e '
          'apaga, como o fundo de uma cena quando a câmera avança.',
    ),
    (
      'A nova chega de longe e assenta',
      'Começa a aparecer quando a de trás já quase sumiu: vem deitada uns '
          '10°, menor e de baixo, e assenta com a curva de chegada.',
    ),
    (
      'Nunca as duas juntas',
      'As telas do Cajui não têm fundo próprio. Se uma esmaecesse por cima '
          'da outra, os itens da tela velha apareceriam através da nova.',
    ),
    (
      'Voltar é o contrário',
      'A câmera recua: a tela da frente sai pelo mesmo caminho, e a de trás '
          'volta ao tamanho.',
    ),
  ];

  static const _orbit = [
    (
      'A câmera rodeia a cena',
      'A aba que chega vem do lado da ida, girada uns 34°; a que sai vai '
          'para o lado oposto. Uma aba à direita na barra chega pela '
          'direita.',
    ),
    (
      'Nenhuma aba é desmontada',
      'Todas ficam montadas, com o estado de cada uma: a conversa pela '
          'metade, a rolagem do Início. É o que o contador mostra.',
    ),
    (
      'Só a da frente responde',
      'A que sai ainda aparece durante a órbita, mas não recebe toque nem '
          'foco de teclado.',
    ),
  ];
}
