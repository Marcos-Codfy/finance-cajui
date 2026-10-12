import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/overview/overview_figures.dart';
import 'package:gallery/src/pages/overview/overview_highlights.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/pages/screens/widget/glass_widget.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_pager.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A porta de entrada: o que é o Cajui, uma peça viva, por onde começar e
/// os números.
///
/// Antes a gallery abria em Cores, uma grade de amostras com código hex, e
/// o que o projeto tem de especial ficava do 12º item do menu em diante.
/// Quem chega frio tem um minuto: esta página precisa responder nele.
class OverviewPage extends StatelessWidget {
  /// Cria a porta de entrada.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const GalleryPage(
      title: 'Cajui · design system',
      lead:
          'O Cajui é um app Android de finanças pessoais, feito do zero. Esta '
          'gallery é o design system dele funcionando: os componentes, as '
          'telas do app em cada estado, o movimento e o som — com números '
          'inventados.',
      sections: [
        _Showcase(),
        GallerySection(
          title: 'Comece por aqui',
          description: 'O que este projeto tem de diferente, em seis páginas.',
          child: OverviewHighlights(),
        ),
        GallerySection(
          title: 'Em números',
          description: 'Contados do próprio código: mudam sozinhos.',
          child: OverviewFigures(),
        ),
        GallerySection(title: 'Como usar', child: _HowTo()),
      ],
    );
  }
}

class _HowTo extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Tema, som, movimento e a cor da falta ficam em Ajustes. Cada página '
      'termina com a próxima, e o endereço muda junto: dá para mandar o link '
      'de qualquer página.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }
}

/// O widget de vidro da tela inicial, de verdade, e o que ele faz.
class _Showcase extends StatelessWidget {
  const new();

  static const double _widgetWidth = 420;
  static const double _captionWidth = 360;

  @override
  Widget build(BuildContext context) {
    final pager = GalleryPager.maybeOf(context);
    final glass = SizedBox(
      width: _widgetWidth,
      child: GlassWidget(
        label: 'Sobra de outubro',
        amount: BrlFormatter.format(HomeNumbers.leftover),
        caption: 'Depois de pagar tudo, pelo que está lançado.',
        onNumber: pager == null
            ? null
            : () => pager.onOpen(GalleryDestination.homeWidget),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.block),
      child: Wrap(
        spacing: CajuiSpacing.xxl,
        runSpacing: CajuiSpacing.lg,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [glass, _caption(context)],
      ),
    );
  }

  Widget _caption(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _captionWidth),
      child: Text(
        'O widget da tela inicial: vidro sobre a aurora do Cerrado à noite. '
        'Toque no número — no celular, o app cresce de dentro dele e os '
        'números chegam atravessando o vidro.',
        style: theme.typography.body.copyWith(color: theme.colors.text.muted),
      ),
    );
  }
}
