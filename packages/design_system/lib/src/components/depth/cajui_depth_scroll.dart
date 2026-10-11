import 'package:design_system/src/components/depth/depth_item.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// A rolagem em profundidade: o corpo de uma tela feita de seções, em que o
/// conteúdo curva para longe nas bordas como a face de um tambor.
///
/// O que entra por baixo vem deitado, menor e um pouco atrasado; assenta
/// plano quando aparece inteiro; e, ao sair por cima, recua e é coberto pelo
/// seguinte. **Toda seção inteira à vista fica plana**: o efeito mora só na
/// borda, onde nada está sendo lido (veja `DrumPose`).
///
/// Atrás das seções pode ir um [backdrop] — uma luz, uma ilustração —, que
/// sobe a um terço da velocidade da lista: a segunda camada da paralaxe.
///
/// Custo: cada seção ganha um `RepaintBoundary`, e rolar só troca matrizes;
/// nada é remontado nem medido de novo por quadro (ADR-028). No `lite` não há
/// esmaecer; no `reduced` é uma lista comum, plana e parada.
class CajuiDepthScroll extends StatefulWidget {
  /// Cria a rolagem com as seções [children], de cima para baixo.
  const new({
    required this.children,
    this.controller,
    this.padding = const EdgeInsets.all(CajuiSpacing.xl),
    this.backdrop,
    this.physics,
    super.key,
  });

  /// As seções.
  final List<Widget> children;

  /// Quem comanda a rolagem, quando a tela precisa mandar nela.
  final ScrollController? controller;

  /// A margem em volta das seções.
  final EdgeInsetsGeometry padding;

  /// A camada do fundo, que sobe mais devagar que as seções. Enfeite: não
  /// recebe toque nem chega ao leitor de tela.
  final Widget? backdrop;

  /// A física da rolagem. O padrão quica nas pontas, mesmo com pouco
  /// conteúdo: é o que faz a superfície parecer de um material, e não de
  /// uma folha presa.
  final ScrollPhysics? physics;

  /// A física padrão: o quique, sempre rolável.
  static const ScrollPhysics bouncing = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  @override
  State<CajuiDepthScroll> createState() => _CajuiDepthScrollState();
}

class _CajuiDepthScrollState extends State<CajuiDepthScroll> {
  /// O fundo sobe a esta fração da velocidade da lista.
  static const double _backdropSpeed = 0.3;

  ScrollController? _own;

  /// Muda de valor sempre que a lista muda de tamanho sem rolar.
  final ValueNotifier<int> _geometry = ValueNotifier(0);

  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    _geometry.dispose();
    super.dispose();
  }

  bool _remeasured(ScrollMetricsNotification _) {
    _geometry.value++;
    return false;
  }

  int? _indexOf(Key key) {
    final index = widget.children.indexWhere((child) => child.key == key);
    return index < 0 ? null : index;
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = widget.backdrop;
    final list = NotificationListener<ScrollMetricsNotification>(
      onNotification: _remeasured,
      child: ListView.builder(
        controller: _controller,
        padding: widget.padding,
        physics: widget.physics ?? CajuiDepthScroll.bouncing,
        itemCount: widget.children.length,
        // O item leva a chave do filho, e a lista o reencontra por ela
        // quando outro entra antes: o estado dele — a página do carrossel,
        // o que foi digitado — não se perde.
        findChildIndexCallback: _indexOf,
        itemBuilder: (context, index) => DepthItem(
          key: widget.children[index].key,
          geometry: _geometry,
          child: RepaintBoundary(child: widget.children[index]),
        ),
      ),
    );
    if (backdrop == null) return list;
    return Stack(
      children: [
        Positioned.fill(child: _backdrop(context, backdrop)),
        list,
      ],
    );
  }

  /// No `reduced` o fundo fica parado, mas a forma da árvore não muda: o
  /// nível pode trocar no meio da sessão sem remontar nada.
  Widget _backdrop(BuildContext context, Widget backdrop) {
    final moves = motionOf(context) != MotionLevel.reduced;
    return AnimatedBuilder(
      animation: _controller,
      child: ExcludeSemantics(
        child: IgnorePointer(child: RepaintBoundary(child: backdrop)),
      ),
      builder: (context, child) {
        final pixels = moves && _controller.hasClients
            ? _controller.offset
            : 0.0;
        return Transform.translate(
          offset: Offset(0, -pixels * _backdropSpeed),
          child: child,
        );
      },
    );
  }
}
