import 'dart:async';

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
  /// Os relógios da tela ficam ligados só o bastante para a entrada
  /// assentar. Desligados desde o começo, a entrada cinematográfica do
  /// Início nem começaria, e a miniatura mostraria a tela vazia.
  late final Timer _freeze;
  bool _frozen = false;

  @override
  void initState() {
    super.initState();
    _freeze = Timer(CajuiDurations.slowest, () {
      if (mounted) setState(() => _frozen = true);
    });
  }

  @override
  void dispose() {
    _freeze.cancel();
    super.dispose();
  }

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
      child: RepaintBoundary(
        child: IgnorePointer(child: ExcludeSemantics(child: _still(context))),
      ),
    );
  }

  /// O retrato da tela. No movimento reduzido tudo nasce no quadro final
  /// — a resposta da Juju inteira, o número já contado, o esqueleto
  /// parado —, e depois os relógios param: numa vitrine com dezenas de
  /// telas, nenhuma pode ficar respirando em laço nem gastando quadro.
  Widget _still(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return TickerMode(
      enabled: !_frozen,
      // O mesmo número aparece em várias miniaturas; sem isto, um voo
      // entre telas acharia vários heróis com o mesmo nome.
      child: HeroMode(
        enabled: false,
        child: CajuiTheme(
          data: theme.withMotionLevel(MotionLevel.reduced),
          child: FittedBox(
            child: PhoneFrame(child: Builder(builder: widget.variant.builder)),
          ),
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
