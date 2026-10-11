import 'package:design_system/src/components/glow/glow_painter.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:flutter/widgets.dart';

/// Um brilho discreto em volta de um bloco quando ele vira boa notícia: o
/// mês que fechou no verde, a semana que coube.
///
/// Quando [active] passa de falso a verdadeiro, o halo cresce, faíscas de
/// capim dourado sobem e tudo assenta num halo calmo, que fica enquanto a
/// notícia for boa. A festa roda **uma vez** e dura 600 ms — o teto do
/// projeto —, e nunca em laço.
///
/// Quando falta, não acontece nada: sem halo, sem cor, sem som. Má notícia
/// entra em silêncio, e a frase da tela diz o que fazer.
///
/// O brilho é enfeite: o leitor de tela não o percebe, e a boa notícia tem de
/// estar dita em texto no próprio bloco. Fora do nível `full` não há festa —
/// o halo calmo simplesmente aparece.
class CajuiGlow extends StatefulWidget {
  /// Envolve [child] com o brilho, aceso enquanto [active].
  const new({
    required this.active,
    required this.child,
    this.celebrateOnAppear = false,
    this.borderRadius = const BorderRadius.all(CajuiRadius.xl),
    super.key,
  });

  /// Se a notícia é boa agora.
  final bool active;

  /// Faz a festa também quando o bloco já nasce com boa notícia. O app liga
  /// isto só quando a boa notícia é nova — senão a festa se repetiria a cada
  /// vez que a tela abre, e deixaria de significar algo.
  final bool celebrateOnAppear;

  /// O bloco que brilha.
  final Widget child;

  /// O raio de canto do bloco, que o halo acompanha.
  final BorderRadius borderRadius;

  @override
  State<CajuiGlow> createState() => _CajuiGlowState();
}

class _CajuiGlowState extends State<CajuiGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _party = AnimationController(
    vsync: this,
    duration: CajuiDurations.slowest,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.active && widget.celebrateOnAppear) _celebrate();
  }

  @override
  void didUpdateWidget(CajuiGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _celebrate();
    if (!widget.active) _party.stop();
  }

  void _celebrate() {
    final festive = CajuiTheme.of(context).motionLevel.allowsDecorativeMotion;
    if (!festive) return;
    _party.forward(from: 0);
  }

  @override
  void dispose() {
    _party.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    final calm = theme.motionLevel.allowsSpring;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.active ? 1 : 0),
      duration: calm ? CajuiDurations.base : Duration.zero,
      child: widget.child,
      builder: (context, presence, child) => AnimatedBuilder(
        animation: _party,
        child: child,
        builder: (context, child) => CustomPaint(
          painter: GlowPainter(
            presence: presence,
            bloom: _party.isAnimating ? _party.value : null,
            halo: colors.intent.positive,
            spark: colors.brand.gold,
            radius: widget.borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
