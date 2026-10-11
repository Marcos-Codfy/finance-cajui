import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// O número que voa de uma tela para a outra.
///
/// Embrulhe o mesmo valor, com a mesma [tag], nas duas telas — o "Pode
/// gastar" do Início e o título do detalhe — e, ao abrir o detalhe, o número
/// sai do cartão e cresce até o lugar novo. É o elemento compartilhado de
/// "lista → detalhe" do guia de movimento: o olho não perde o número de
/// vista, e por isso não precisa procurá-lo de novo.
///
/// Durante o voo, os dois desenhos — o pequeno e o grande — se fundem, e
/// nenhum deles conta: a cópia que voa é sempre parada. No movimento
/// reduzido não há voo; a tela troca com a fusão curta de sempre.
///
/// Precisa de um `CajuiHeroScope` acima do navegador; o `CajuiAppSurface`
/// já traz um. Na tela de destino, não use `from` no número: ele chega
/// pronto, voando.
class CajuiHeroNumber extends StatelessWidget {
  /// Faz [child] voar entre telas que usem a mesma [tag].
  const new({required this.tag, required this.child, super.key});

  /// O que identifica o número nas duas telas: `'week-left'`, por exemplo.
  final Object tag;

  /// O número, já desenhado.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final flies = CajuiTheme.of(context).motionLevel.allowsSpring;
    return HeroMode(
      enabled: flies,
      child: Hero(
        // O prefixo separa os números de qualquer outro herói do app: uma
        // foto com a mesma etiqueta nunca voaria para o lugar de um valor.
        tag: ('cajui.number', tag),
        flightShuttleBuilder: _flight,
        child: child,
      ),
    );
  }

  /// A cópia que voa: o desenho de partida some enquanto o de chegada
  /// aparece, os dois esticados à caixa do voo, que cresce de um tamanho ao
  /// outro. O tema da cópia é o reduzido, para nada contar no ar.
  static Widget _flight(
    BuildContext flight,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final from = (fromContext.widget as Hero).child;
    final to = (toContext.widget as Hero).child;
    // Na ida, a tela de cima é a de chegada; na volta, a de partida. A
    // animação vai de 0 a 1 na ida e de 1 a 0 na volta, então a tela de cima
    // sempre aparece com ela, e a de baixo com o inverso.
    final pushing = direction == HeroFlightDirection.push;
    final (top, bottom) = pushing ? (to, from) : (from, to);
    final theme = CajuiTheme.of(toContext);
    return ExcludeSemantics(
      child: CajuiTheme(
        data: theme.withMotionLevel(MotionLevel.reduced),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _fitted(bottom, ReverseAnimation(animation)),
            _fitted(top, animation),
          ],
        ),
      ),
    );
  }

  static Widget _fitted(Widget child, Animation<double> opacity) {
    return FadeTransition(
      opacity: opacity,
      child: FittedBox(child: child),
    );
  }
}
