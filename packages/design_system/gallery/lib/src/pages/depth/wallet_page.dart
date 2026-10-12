import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_showcase.dart';
import 'package:gallery/src/pages/depth/depth_stage.dart';
import 'package:gallery/src/pages/depth/month_sample.dart';
import 'package:gallery/src/pages/depth/motion_level_chips.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A pilha de carteira, com os cartões 3D da tela de Cartões.
class WalletPage extends StatefulWidget {
  /// Cria a página.
  const new({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  /// Trocar a chave remonta a pilha, e o maço se abre de novo.
  int _deal = 0;

  /// Cartões fictícios, com nomes de árvore do Cerrado, em cada degrau do
  /// limite.
  static const _cards = [
    ('Cartão Pequi', 'fecha dia 3 · vence dia 10', 41290, 250000),
    ('Cartão Ipê', 'fecha dia 25 · vence dia 5', 124000, 200000),
    ('Cartão Buriti', 'fecha dia 12 · vence dia 20', 301050, 350000),
  ];

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Pilha de cartões',
      lead:
          'Os cartões saem de um maço ao aparecer, param no alto da tela e '
          'se empilham conforme se rola, e se abrem em leque quando se puxa '
          'além do topo. Parada e à vista, é uma coluna comum.',
      sections: [_live(context), _levels()],
    );
  }

  Widget _live(BuildContext context) {
    return GallerySection(
      title: 'Ao vivo',
      description:
          'Role para baixo dentro do aparelho e veja a carteira se fechar; '
          'volte e ela se abre. Um toque ainda vira cada cartão.',
      child: DepthShowcase(
        notes: _notes,
        stage: DepthStage(
          child: CajuiDepthScroll(
            children: [
              MonthSample.heading(context, 'Cartões de crédito'),
              CajuiWalletStack(
                key: ValueKey(_deal),
                children: [for (final card in _cards) _plastic(card)],
              ),
              const SizedBox(height: CajuiSpacing.xl),
              const CajuiSectionTitle('Últimos lançamentos'),
              MonthSample.rows(MonthSample.entries),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levels() {
    return GallerySection(
      title: 'Nível de movimento',
      description:
          'No leve, a pilha se mexe sem escurecer os de trás. No reduzido, é '
          'só a coluna, desde o primeiro quadro.',
      child: MotionLevelChips(
        action: CajuiButton(
          label: 'Abrir o maço de novo',
          size: CajuiButtonSize.compact,
          onPressed: () => setState(() => _deal++),
        ),
      ),
    );
  }

  static Widget _plastic((String, String, int, int) card) {
    final (name, detail, used, limit) = card;
    return CajuiCreditCard3D(
      name: name,
      detail: detail,
      usedCents: used,
      limitCents: limit,
    );
  }

  static const _notes = [
    (
      'O maço',
      'O da frente sai primeiro e desce até o último lugar; o de trás só '
          'cresce e assenta. Dentro de uma entrada cinematográfica, o maço '
          'abre no ritmo dela.',
    ),
    (
      'A pilha no alto',
      'Cada cartão que chega à borda de cima para ali, e o seguinte o '
          'cobre; os de trás recuam e mostram só a beirada. Quando o último '
          'chega, a pilha vai embora junta.',
    ),
    (
      'O leque',
      'Puxando além do topo, cada cartão se afasta um pouco mais que o de '
          'cima — é a física que quica da rolagem em profundidade.',
    ),
    (
      'O que não muda',
      'O layout é sempre o da coluna aberta: a rolagem não pula, o toque '
          'acha o cartão onde ele aparece, e a ordem de leitura é a da lista.',
    ),
  ];
}
