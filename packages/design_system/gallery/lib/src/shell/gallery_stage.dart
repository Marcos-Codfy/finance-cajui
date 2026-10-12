import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_location.dart';
import 'package:gallery/src/shell/gallery_pager.dart';
import 'package:gallery/src/shell/gallery_pages.dart';

/// A área da página aberta.
///
/// A troca de página é uma passagem, como a troca de tela do app
/// (`CameraMove`): a página que sai some na primeira metade, e a nova só
/// aparece na segunda. A fusão de antes mostrava as duas, uma através da
/// outra — o mesmo defeito que o dono apontou no app.
class GalleryStage extends StatelessWidget {
  /// Cria a área com a página de [location].
  const new({required this.location, required this.onOpen, super.key});

  /// A página aberta.
  final GalleryLocation location;

  /// Abre outra página.
  final GalleryOpen onOpen;

  /// Cada página leva o seu próprio [GalleryPager]: a que sai continua
  /// mostrando o rodapé dela enquanto se apaga, sem trocar de texto no meio.
  @override
  Widget build(BuildContext context) {
    final reduced = CajuiTheme.of(context).motionLevel == MotionLevel.reduced;
    return AnimatedSwitcher(
      duration: reduced ? CajuiDurations.reducedFade : CajuiDurations.base,
      transitionBuilder: _handOver,
      layoutBuilder: _pinnedToTop,
      child: KeyedSubtree(
        key: ValueKey(location.page),
        child: GalleryPager(
          current: location.page,
          onOpen: onOpen,
          onState: (state) => _follow(context, state),
          child: galleryPageOf(location.page, state: location.state),
        ),
      ),
    );
  }

  /// O endereço acompanha o estado escolhido na tela, trocando o endereço
  /// em vigor em vez de criar outro: o Voltar do navegador volta para a
  /// página de antes, e não para cada estado tocado.
  void _follow(BuildContext context, String state) =>
      Router.neglect(context, () => onOpen(location.page, state: state));
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
