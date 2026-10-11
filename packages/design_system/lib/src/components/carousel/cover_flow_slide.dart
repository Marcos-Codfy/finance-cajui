import 'package:design_system/src/motion/space_pose.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Uma página do `CajuiCoverFlow`, já na pose do quadro.
///
/// Só a página do centro recebe toque no conteúdo; tocar numa vizinha traz
/// ela para o centro — o jeito de trocar de página sem arrastar
/// (RNF-A11Y-10). A forma da árvore é a mesma nos dois papéis, para a página
/// não perder estado quando passa pelo centro.
class CoverFlowSlide extends StatelessWidget {
  /// Cria a página [index] de [count], na [pose] do quadro.
  const new({
    required this.index,
    required this.count,
    required this.pose,
    required this.width,
    required this.centered,
    required this.onSummon,
    required this.child,
    super.key,
  });

  /// A posição da página, a partir de 0.
  final int index;

  /// Quantas páginas o carrossel tem.
  final int count;

  /// Onde a página está neste quadro.
  final SpacePose pose;

  /// A largura da página.
  final double width;

  /// Se esta é a página do centro.
  final bool centered;

  /// Traz a página para o centro: o toque numa vizinha, o foco do teclado e
  /// o foco do leitor de tela.
  final VoidCallback onSummon;

  /// O conteúdo.
  final Widget child;

  /// O que o leitor de tela ouve antes do conteúdo da página.
  static String spoken(int index, int count) => 'Página ${index + 1} de $count';

  /// A matriz vem por fora: o toque passa por ela antes de qualquer outro
  /// limite, e a vizinha é tocável onde aparece — fora da própria caixa.
  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: pose.pivot,
      transform: pose.local,
      child: Opacity(
        opacity: pose.opacity,
        // Página invisível continua na leitura: quem ouve percorre todas, e
        // o foco nela a traz para o centro.
        alwaysIncludeSemantics: true,
        child: Semantics(
          container: true,
          sortKey: OrdinalSortKey(index.toDouble()),
          label: spoken(index, count),
          onDidGainAccessibilityFocus: centered ? null : onSummon,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (focused) {
              if (focused) onSummon();
            },
            child: _touch(),
          ),
        ),
      ),
    );
  }

  Widget _touch() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: centered ? null : onSummon,
      child: IgnorePointer(
        ignoring: !centered,
        child: SizedBox(
          width: width,
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
