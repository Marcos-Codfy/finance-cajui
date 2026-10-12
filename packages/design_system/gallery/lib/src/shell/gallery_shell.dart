import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_nav.dart';
import 'package:gallery/src/shell/gallery_pager.dart';
import 'package:gallery/src/shell/gallery_pages.dart';
import 'package:gallery/src/shell/gallery_toolbar.dart';

/// A casca da gallery: menu, controles e a página aberta.
///
/// Em tela larga o menu fica ao lado; em tela estreita vira uma fileira de
/// chips no topo. A gallery roda no navegador e no aparelho, e nos dois
/// precisa dar para chegar a qualquer página com um toque.
class GalleryShell extends StatefulWidget {
  /// Cria a casca.
  const new({super.key});

  @override
  State<GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<GalleryShell> {
  GalleryDestination _selected = GalleryDestination.values.first;

  /// A partir desta largura o menu cabe ao lado sem apertar o conteúdo.
  static const double _wideFrom = 840;
  static const double _navWidth = 272;

  void _select(GalleryDestination destination) =>
      setState(() => _selected = destination);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideFrom;
    return SafeArea(
      child: wide ? _wideLayout(context) : _narrowLayout(context),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _navWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Masthead(),
              Expanded(
                child: GalleryNav(selected: _selected, onSelect: _select),
              ),
              const Padding(
                padding: EdgeInsets.all(CajuiSpacing.xxl),
                child: GalleryToolbar(),
              ),
            ],
          ),
        ),
        const _Rule(vertical: true),
        Expanded(child: _page(context)),
      ],
    );
  }

  Widget _narrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Masthead(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: CajuiSpacing.xxl),
          child: GalleryToolbar(),
        ),
        _chips(),
        const _Rule(vertical: false),
        Expanded(child: _page(context)),
      ],
    );
  }

  Widget _chips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: CajuiSpacing.xxl,
        vertical: CajuiSpacing.md,
      ),
      child: Row(
        spacing: CajuiSpacing.sm,
        children: [
          for (final destination in GalleryDestination.values)
            CajuiChip(
              label: destination.title,
              selected: destination == _selected,
              onSelected: (_) => _select(destination),
            ),
        ],
      ),
    );
  }

  /// A troca de página é uma passagem, como a troca de tela do app
  /// (`CameraMove`): a página que sai some na primeira metade, e a nova só
  /// aparece na segunda. A fusão de antes mostrava as duas, uma através da
  /// outra — o mesmo defeito que o dono apontou no app.
  ///
  /// Cada página leva o seu próprio [GalleryPager]: a que sai continua
  /// mostrando o rodapé dela enquanto se apaga, sem trocar de texto no meio.
  Widget _page(BuildContext context) {
    final reduced = CajuiTheme.of(context).motionLevel == MotionLevel.reduced;
    return AnimatedSwitcher(
      duration: reduced ? CajuiDurations.reducedFade : CajuiDurations.base,
      transitionBuilder: _handOver,
      layoutBuilder: _pinnedToTop,
      child: KeyedSubtree(
        key: ValueKey(_selected),
        child: GalleryPager(
          current: _selected,
          onSelect: _select,
          child: galleryPageOf(_selected),
        ),
      ),
    );
  }
}

/// A que chega anda de 0 a 1; a que sai, de 1 a 0. Com o intervalo na
/// metade de cima, cada uma só aparece enquanto a outra está apagada.
Widget _handOver(Widget child, Animation<double> animation) => FadeTransition(
  opacity: CurvedAnimation(parent: animation, curve: const Interval(0.5, 1)),
  child: child,
);

/// Toda página ocupa a área inteira e começa no alto. O arranjo padrão do
/// `AnimatedSwitcher` centraliza: página mais curta que a janela boiava no
/// meio, e o título mudava de altura a cada troca.
Widget _pinnedToTop(Widget? current, List<Widget> previous) => Stack(
  fit: StackFit.expand,
  alignment: Alignment.topLeft,
  children: [...previous, ?current],
);

class _Masthead extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CajuiSpacing.xxl,
        CajuiSpacing.xxl,
        CajuiSpacing.xxl,
        CajuiSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cajui',
            style: theme.typography.headline.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          Text(
            'Design system · sample navegável',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const new({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: vertical ? 1 : null,
      height: vertical ? null : 1,
      color: CajuiTheme.of(context).colors.border.subtle,
    );
  }
}
