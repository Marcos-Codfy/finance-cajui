import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// As peças que a rodada de 16/10/2026 trouxe ao design system: as portas
/// do Início em grade, o "Mais", o puxar para atualizar e a cor do cartão
/// escolhida por bolinhas.
abstract final class DoorsSections {
  /// As seções, na ordem da página.
  static List<Widget> get all => const [_Doors(), _PullDemo(), _SkinDemo()];
}

class _Doors extends StatelessWidget {
  const new();

  static void _nothing() {}

  static const Widget _grid = CajuiTileGrid(
    children: [
      CajuiTile(
        icon: CajuiIconData.receipt,
        title: 'Lançamentos',
        subtitle: '12 este mês',
        onPressed: _nothing,
      ),
      CajuiTile(
        icon: CajuiIconData.calendar,
        title: 'Meu mês',
        subtitle: 'Entra e sai do bolso',
        onPressed: _nothing,
      ),
      CajuiTile(
        icon: CajuiIconData.card,
        title: 'Cartões',
        subtitle: 'Quanto do limite já foi usado no mês',
        onPressed: _nothing,
      ),
      CajuiTile(
        icon: CajuiIconData.debt,
        title: 'Dívidas',
        subtitle: 'Tudo quitado',
        onPressed: _nothing,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Portas em grade e o "Mais"',
    description:
        'As quatro portas mais usadas do Início em ladrilhos de dois em '
        'dois, cada par da mesma altura; o resto fica num "Mais" que abre e '
        'fecha, sem sumir.',
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _grid,
          CajuiDisclosure(
            title: 'Mais',
            children: [
              CajuiListRow(title: 'Minhas contas', subtitle: 'O que entra'),
              CajuiListRow(title: 'Mês a mês', subtitle: 'Cada mês'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PullDemo extends StatefulWidget {
  const new();

  @override
  State<_PullDemo> createState() => _PullDemoState();
}

class _PullDemoState extends State<_PullDemo> {
  int _times = 0;

  Future<void> _refresh() async {
    await Future<void>.delayed(CajuiDurations.slowest);
    if (mounted) setState(() => _times++);
  }

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Puxar para atualizar',
    description:
        'Do topo, puxar para baixo e soltar atualiza — no Início, força a '
        'sincronização. Sem o Material: ouve a rolagem que estiver dentro.',
    child: SizedBox(
      height: 220,
      width: 420,
      child: CajuiPullToRefresh(
        onRefresh: _refresh,
        child: ListView(
          children: [
            CajuiListRow(
              title: 'Puxe esta lista para baixo',
              subtitle: _times == 0
                  ? 'Ainda não atualizou'
                  : 'Atualizou $_times ${_times == 1 ? 'vez' : 'vezes'}',
            ),
            for (var row = 1; row <= 4; row++)
              CajuiListRow(title: 'Linha $row'),
          ],
        ),
      ),
    ),
  );
}

class _SkinDemo extends StatefulWidget {
  const new();

  @override
  State<_SkinDemo> createState() => _SkinDemoState();
}

class _SkinDemoState extends State<_SkinDemo> {
  CajuiCardSkin _skin = CajuiCardSkin.ipeRoxo;

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Cor do cartão',
    description:
        'Os tons do cerrado em bolinhas, com o cartão mudando ao vivo em '
        'cima: escolhe-se vendo a cor, não lendo o nome dela.',
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CajuiSpacing.lg,
        children: [
          CajuiCreditCard3D(
            name: 'Cartão ${_skin.label}',
            detail: 'fecha dia 3 · vence dia 10',
            usedCents: 0,
            limitCents: 1,
            skin: _skin,
          ),
          CajuiCardSkinPicker(
            selected: _skin,
            onChanged: (skin) => setState(() => _skin = skin),
          ),
        ],
      ),
    ),
  );
}
