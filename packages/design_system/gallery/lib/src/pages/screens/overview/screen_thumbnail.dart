import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// A miniatura de um estado: a tela de verdade, no aparelho, reduzida, com
/// o nome do estado embaixo. Tocar nela abre a tela grande nesse estado.
///
/// É a tela montada, e não uma imagem guardada: o que a vitrine mostra é
/// o que a página da tela mostra, no tema em vigor, sem foto para
/// envelhecer.
class ScreenThumbnail extends StatefulWidget {
  /// Cria a miniatura do estado [variant] da tela [screen].
  const new({
    required this.screen,
    required this.variant,
    required this.onOpen,
    super.key,
  });

  /// O nome da tela, para o leitor de tela dizer de qual é o estado.
  final String screen;

  /// O estado mostrado.
  final ScreenVariant variant;

  /// O que acontece ao tocar: abrir a tela grande nesse estado.
  final VoidCallback onOpen;

  /// A largura da miniatura: numa tela de computador, cabem seis por
  /// fileira, e o nome do estado ainda se lê.
  static const double width = 150;

  /// A moldura do aparelho tem a proporção de 1 para 2 (390 × 780).
  static const double _pictureHeight = width * 2;

  /// A altura inteira: o aparelho, o respiro e até duas linhas de nome.
  static const double height =
      _pictureHeight + CajuiSpacing.sm + CajuiSpacing.block;

  /// O raio da moldura, reduzido na mesma escala que a tela.
  static const _radius = BorderRadius.all(CajuiRadius.sm);

  @override
  State<ScreenThumbnail> createState() => _ScreenThumbnailState();
}

class _ScreenThumbnailState extends State<ScreenThumbnail> {
  static bool _lifted(Set<WidgetState> states) =>
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused);

  @override
  Widget build(BuildContext context) {
    return CajuiPressable(
      onPressed: widget.onOpen,
      semanticLabel: '${widget.screen}: ${widget.variant.label}. Abrir',
      touch: CajuiTouch.card,
      radius: ScreenThumbnail._radius,
      builder: (context, states) => SizedBox(
        width: ScreenThumbnail.width,
        height: ScreenThumbnail.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _picture(context, lifted: _lifted(states)),
            const SizedBox(height: CajuiSpacing.sm),
            Expanded(child: _label(context, lifted: _lifted(states))),
          ],
        ),
      ),
    );
  }

  /// O aparelho com a tela. Passar o mouse levanta a miniatura, para que
  /// se veja qual vai abrir antes de clicar.
  Widget _picture(BuildContext context, {required bool lifted}) {
    return AnimatedContainer(
      duration: CajuiDurations.fast,
      width: ScreenThumbnail.width,
      height: ScreenThumbnail._pictureHeight,
      decoration: BoxDecoration(
        borderRadius: ScreenThumbnail._radius,
        boxShadow: lifted ? CajuiShadows.floating : CajuiShadows.raised,
      ),
      child: Stack(
        children: [
          RepaintBoundary(
            // A tela pequena não recebe toque, leitor de tela nem foco: sem
            // o ExcludeFocus, o Tab entrava nos botões e campos de cada
            // miniatura, e o Enter acionava o botão de dentro em vez de abrir
            // a tela.
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ExcludeFocus(child: _still(context)),
              ),
            ),
          ),
          if (widget.variant.moving) _movingBadge(context),
        ],
      ),
    );
  }

  /// O selo do estado que só se vê em movimento: parada, a tela é igual à
  /// do vizinho, e sem o selo a vitrine parecia ter um estado repetido.
  Widget _movingBadge(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Positioned(
      left: CajuiSpacing.sm,
      bottom: CajuiSpacing.sm,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.surface.elevated,
          borderRadius: const BorderRadius.all(CajuiRadius.pill),
          boxShadow: CajuiShadows.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CajuiSpacing.sm,
            vertical: CajuiSpacing.xs,
          ),
          child: Text(
            'Com animação',
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// O retrato da tela, no movimento reduzido: tudo nasce no quadro final
  /// — a resposta da Juju inteira, o número já contado — e nada respira
  /// em laço (o esqueleto e os três pontos ficam parados), então numa
  /// vitrine com dezenas de telas nenhuma fica gastando quadro.
  ///
  /// Os relógios não são desligados: desligá-los por tempo (600 ms)
  /// congelava a entrada do Início no meio quando o navegador demorava a
  /// montar a página, e a miniatura saía vazia. A entrada reduzida dura
  /// 120 ms e para sozinha.
  Widget _still(BuildContext context) {
    final theme = CajuiTheme.of(context);
    // O mesmo número aparece em várias miniaturas; sem isto, um voo entre
    // telas acharia vários heróis com o mesmo nome.
    return HeroMode(
      enabled: false,
      child: CajuiTheme(
        data: theme.withMotionLevel(MotionLevel.reduced),
        child: FittedBox(
          child: PhoneFrame(child: Builder(builder: widget.variant.builder)),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, {required bool lifted}) {
    final theme = CajuiTheme.of(context);
    return Text(
      widget.variant.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.caption.copyWith(
        color: lifted ? theme.colors.text.primary : theme.colors.text.muted,
      ),
    );
  }
}
