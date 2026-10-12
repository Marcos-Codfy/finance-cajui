import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/widget/widget_demo.dart';

/// O widget da tela inicial: vidro sobre a aurora, e o app que nasce dele.
class HomeWidgetPage extends StatelessWidget {
  /// Cria a página do widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Widget',
      lead:
          'A sobra do mês na tela inicial, num painel de vidro sobre a aurora '
          'do Cerrado à noite, com duas esferas de luz flutuando por fora. '
          'Tocar no número abre o Cajui crescendo de dentro do widget, e os '
          'números do Início chegam atravessando o vidro.',
      variants: [
        ScreenVariant(
          label: 'Na tela inicial',
          note:
              'Toque no número: o app cresce do widget (Android 12+) e o '
              'Início recebe os números pelo vidro, com o pop do card.',
          builder: (_) => const WidgetDemo(),
        ),
        ScreenVariant(
          label: 'Mês novo',
          note:
              'Passado o mês do número, o widget não o mostra: pede para '
              'abrir o app, que publica o novo.',
          builder: (_) => const WidgetDemo(stale: true),
        ),
      ],
    );
  }
}
