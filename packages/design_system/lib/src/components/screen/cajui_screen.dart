import 'package:design_system/src/components/button/cajui_icon_button.dart';
import 'package:design_system/src/components/depth/cajui_depth_scroll.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/motion/cajui_cinematic_entrance.dart';
import 'package:design_system/src/motion/cajui_cinematic_shot.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O esqueleto de toda tela: título, conteúdo rolável e, se houver, a área de
/// ação presa embaixo — onde o polegar alcança.
///
/// O título rola junto com o conteúdo, em vez de ocupar uma barra fixa: em
/// tela de celular, cada linha presa no topo é uma linha a menos de dado.
///
/// Tela de painel pode ligar a profundidade ([depth]) e a entrada
/// cinematográfica ([cinematic]) sem montar nada à mão: o título e cada
/// filho viram seções da `CajuiDepthScroll` e tomadas da
/// `CajuiCinematicEntrance`, na ordem em que estão.
class CajuiScreen extends StatelessWidget {
  /// Cria a tela [title] com o conteúdo [children].
  const new({
    required this.title,
    required this.children,
    this.overline,
    this.onBack,
    this.trailing,
    this.footer,
    this.controller,
    this.depth = false,
    this.backdrop,
    this.cinematic = false,
    this.replayKey,
    super.key,
  });

  /// O título da tela.
  final String title;

  /// A linha miúda acima do título: o mês, a semana, o passo.
  final String? overline;

  /// O conteúdo, de cima para baixo.
  final List<Widget> children;

  /// Se dado, a tela mostra o botão de voltar, que chama isto.
  final VoidCallback? onBack;

  /// Uma ação de canto, na altura do botão de voltar.
  final Widget? trailing;

  /// As ações principais, presas ao pé da tela.
  final Widget? footer;

  /// Quem comanda a rolagem, quando a tela precisa mandar nela — uma conversa
  /// que acompanha a mensagem nova, por exemplo.
  final ScrollController? controller;

  /// Liga a rolagem em profundidade: as seções curvam nas bordas da tela e
  /// a superfície quica nas pontas. Para tela de painel, como o Início — em
  /// formulário, o efeito só atrapalharia.
  final bool depth;

  /// Com [depth], a camada do fundo, que sobe mais devagar que as seções.
  final Widget? backdrop;

  /// Liga a entrada cinematográfica: o título e cada filho chegam da
  /// profundidade, nessa ordem, uma vez por montagem.
  final bool cinematic;

  /// Com [cinematic], a chave que faz a entrada rodar de novo: o mês.
  final Object? replayKey;

  /// A largura máxima do conteúdo. Em janela larga, a tela não estica: linha
  /// comprida demais cansa a leitura.
  static const double maxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    final foot = footer;
    // O teclado sobe por cima de tudo: sem Material por baixo, ninguém encolhe
    // a tela por conta própria. Sem isto, o campo de digitar fica escondido
    // justamente enquanto se digita nele.
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: CajuiDurations.fast,
      curve: CajuiCurves.standard,
      child: SafeArea(
        bottom: foot != null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _content(context)),
                if (foot != null)
                  Padding(
                    padding: const EdgeInsets.all(CajuiSpacing.xl),
                    child: foot,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (depth || cinematic) return _staged(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(CajuiSpacing.xl),
      children: [
        if (onBack != null || trailing != null) _corner(),
        ..._header(context),
        ...children,
      ],
    );
  }

  /// A tela encenada: o alto (canto e título) é um bloco só, para curvar e
  /// chegar inteiro, e cada filho é um bloco depois dele.
  Widget _staged(BuildContext context) {
    final blocks = [_top(context), ...children];
    final scenes = cinematic
        ? [
            for (final (index, block) in blocks.indexed)
              CajuiCinematicShot(index: index, child: block),
          ]
        : blocks;
    // A margem da rolagem em profundidade já é a mesma da tela comum.
    final list = depth
        ? CajuiDepthScroll(
            controller: controller,
            backdrop: backdrop,
            children: scenes,
          )
        : ListView(
            controller: controller,
            padding: const EdgeInsets.all(CajuiSpacing.xl),
            children: scenes,
          );
    if (!cinematic) return list;
    return CajuiCinematicEntrance(replayKey: replayKey, child: list);
  }

  Widget _top(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBack != null || trailing != null) _corner(),
        ..._header(context),
      ],
    );
  }

  Widget _corner() {
    final back = onBack;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (back != null)
          CajuiIconButton(
            icon: CajuiIconData.chevronLeft,
            semanticLabel: 'Voltar',
            onPressed: back,
          )
        else
          const SizedBox.shrink(),
        ?trailing,
      ],
    );
  }

  List<Widget> _header(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final above = overline;
    return [
      const SizedBox(height: CajuiSpacing.lg),
      if (above != null)
        Text(
          above.toUpperCase(),
          style: theme.typography.overline.copyWith(
            color: theme.colors.text.faint,
          ),
        ),
      Semantics(
        header: true,
        child: Text(
          title,
          style: theme.typography.headline.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
      ),
      const SizedBox(height: CajuiSpacing.xl),
    ];
  }
}
